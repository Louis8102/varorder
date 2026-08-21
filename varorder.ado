*! varorder 1.0.0 21aug2026
*! conservative automatic temporal ordering for wide-format data
program define varorder, rclass
    version 16.0
    syntax [, UNDO]

    if "`undo'" != "" {
        _varorder_undo
        return add
        exit
    }

    quietly _varorder_plan
    local old `r(oldorder)'
    local proposed `r(neworder)'
    local k = r(k)
    local nfdet = r(n_families_detected)
    local nfcon = r(n_families_confirmed)
    local nfrel = r(n_families_related)
    local nfamb = r(n_families_ambiguous)
    local nfchanged = r(n_families_changed)
    local nfsup = r(n_families_suppressed)
    local nmove = r(n_moved)
    local maxdisp = r(max_displacement)
    local fams `r(family_names)'
    local fstates `r(family_states)'
    local freasons `r(family_reasons)'

    local nf : word count `fams'
    local conuniq ""
    local reltext ""
    local ambtext ""
    local gaptext ""
    local relshown 0
    local ambshown 0
    local gapshown 0
    local ngap 0
    forvalues i = 1/`nf' {
        local f : word `i' of `fams'
        local s : word `i' of `fstates'
        local q : word `i' of `freasons'
        if "`s'" == "confirmed" {
            local fp : list posof "`f'" in conuniq
            if !`fp' local conuniq "`conuniq' `f'"
            if "`q'" == "gap" {
                local ++ngap
                if `gapshown' < 8 {
                    if "`gaptext'" == "" local gaptext "`f': missing indexed position"
                    else local gaptext "`gaptext'; `f': missing indexed position"
                    local ++gapshown
                }
            }
        }
        else {
            local readable "`q'"
            if "`q'" == "explicit_non_temporal" local readable "non-temporal meaning established"
            else if "`q'" == "temporal_unverified" local readable "temporal meaning unverified"
            else if "`q'" == "construct_conflict" local readable "construct conflict"
            else if "`q'" == "position_conflict" local readable "temporal-position conflict"
            else if "`q'" == "temporal_conflict" local readable "metadata conflict"
            else if "`q'" == "normalized_key_collision" local readable "normalized-key collision"
            else if "`q'" == "hierarchy_ambiguous" local readable "hierarchy ambiguous"
            if "`s'" == "related" & `relshown' < 8 {
                if "`reltext'" == "" local reltext "`f': `readable'"
                else local reltext "`reltext'; `f': `readable'"
                local ++relshown
            }
            else if "`s'" == "ambiguous" & `ambshown' < 8 {
                if "`ambtext'" == "" local ambtext "`f': `readable'"
                else local ambtext "`ambtext'; `f': `readable'"
                local ++ambshown
            }
        }
    }
    local conuniq : list retokenize conuniq
    local nconstems : word count `conuniq'
    local constemtext ""
    local constemshown = min(`nconstems', 12)
    if `constemshown' {
        forvalues u = 1/`constemshown' {
            local f : word `u' of `conuniq'
            local fc 0
            forvalues i = 1/`nf' {
                local fi : word `i' of `fams'
                local si : word `i' of `fstates'
                if "`si'" == "confirmed" & "`fi'" == "`f'" local ++fc
            }
            local flabel "`f'"
            if `fc' > 1 local flabel "`f' (`fc')"
            if "`constemtext'" == "" local constemtext "`flabel'"
            else local constemtext "`constemtext', `flabel'"
        }
    }
    if "`constemtext'" == "" local constemtext "none"
    local constemmore = max(0, `nconstems' - `constemshown')
    local relmore = max(0, `nfrel' - `relshown')
    local ambmore = max(0, `nfamb' - `ambshown')
    local gapmore = max(0, `ngap' - `gapshown')

    di as txt ""
    di as txt "varorder preview summary"
    di as txt "  Examined: `k' variables; candidate structures: `nfdet'"
    di as txt "  Confirmed: `nfcon'; stems: `constemtext'" _continue
    if `constemmore' di as txt " (+`constemmore' stems omitted)"
    else di as txt ""
    if `ngap' {
        di as txt "  Gap warning - ordering allowed (`ngap'): `gaptext'" _continue
        if `gapmore' di as txt " (+`gapmore' omitted)"
        else di as txt ""
    }
    if `nfrel' {
        di as txt "  Related/unverified - no action (`nfrel'): `reltext'" _continue
        if `relmore' di as txt " (+`relmore' omitted)"
        else di as txt ""
    }
    if `nfamb' {
        di as txt "  Ambiguous/conflicting - no action (`nfamb'): `ambtext'" _continue
        if `ambmore' di as txt " (+`ambmore' omitted)"
        else di as txt ""
    }
    di as txt "  Proposed: `nfchanged' structures; `nmove' variables; maximum displacement `maxdisp' columns"

    if "`old'" == "`proposed'" {
        di as result "varorder postview summary"
        di as txt "  Updated: no; no variable-order changes were required."
        _varorder_returns, oldorder(`"`old'"') neworder(`"`old'"') k(`k') changed(0) ///
            nfdet(`nfdet') nfcon(`nfcon') nfrel(`nfrel') nfamb(`nfamb') ///
            nfchanged(0) nfsup(`nfsup') nmove(0) maxdisp(0)
        return add
        exit
    }

    global VARORDER_CONFIRM_RESPONSE ""
    display as txt "If you want to proceed, please press Enter." _request(VARORDER_CONFIRM_RESPONSE)
    local __vo_answer "${VARORDER_CONFIRM_RESPONSE}"
    macro drop VARORDER_CONFIRM_RESPONSE
    local __vo_confirmed = ("`__vo_answer'" == "" & lower(c(mode)) != "batch")
    if !`__vo_confirmed' {
        di as result "varorder postview summary"
        di as txt "  Updated: no; confirmation declined; dataset unchanged."
        _varorder_returns, oldorder(`"`old'"') neworder(`"`old'"') k(`k') changed(0) ///
            nfdet(`nfdet') nfcon(`nfcon') nfrel(`nfrel') nfamb(`nfamb') ///
            nfchanged(0) nfsup(`nfsup') nmove(0) maxdisp(0)
        return add
        exit
    }

    _varorder_apply, neworder(`proposed') expectedold(`old')
    local changed = r(changed)
    di as result ""
    di as result "varorder postview summary"
    di as txt "  Updated: yes; examined `k'; reorganized `nfchanged'; moved `nmove'; maximum displacement `maxdisp' columns"
    _varorder_returns, oldorder(`"`old'"') neworder(`"`proposed'"') k(`k') changed(`changed') ///
        nfdet(`nfdet') nfcon(`nfcon') nfrel(`nfrel') nfamb(`nfamb') ///
        nfchanged(`nfchanged') nfsup(`nfsup') nmove(`nmove') maxdisp(`maxdisp')
    return add
end

program define _varorder_plan, rclass
    version 16.0
    unab __vo_old : _all
    local __vo_k : word count `__vo_old'
    forvalues __vo_i = 1/`__vo_k' {
        local __vo_v : word `__vo_i' of `__vo_old'
        local __vo_lab`__vo_i' : variable label `__vo_v'
        notes _count __vo_nn : `__vo_v'
        local __vo_note`__vo_i' ""
        if `__vo_nn' > 0 {
            forvalues __vo_j = 1/`__vo_nn' {
                notes _fetch __vo_one_note : `__vo_v' `__vo_j'
                local __vo_note`__vo_i' `"`__vo_note`__vo_i'' `__vo_one_note'"'
            }
        }
    }
    mata: _varorder_make_plan()

    return scalar k = `__vo_k'
    return scalar n_families_detected = real("`__vo_nfdet'")
    return scalar n_families_confirmed = real("`__vo_nfcon'")
    return scalar n_families_related = real("`__vo_nfrel'")
    return scalar n_families_ambiguous = real("`__vo_nfamb'")
    return scalar n_families_suppressed = real("`__vo_nfrel'") + real("`__vo_nfamb'")
    return scalar n_families_changed = real("`__vo_nfchanged'")
    return scalar n_moved = real("`__vo_nmove'")
    return scalar max_displacement = real("`__vo_maxdisp'")
    return scalar order_lists_returned = 1
    return local oldorder `"`__vo_old'"'
    return local neworder `"`__vo_new'"'
    return local class_variables `"`__vo_classvars'"'
    return local class_families `"`__vo_classfams'"'
    return local class_states `"`__vo_classstates'"'
    return local class_keys `"`__vo_classkeys'"'
    return local class_reasons `"`__vo_classreasons'"'
    return local family_names `"`__vo_families'"'
    return local family_states `"`__vo_fstates'"'
    return local family_reasons `"`__vo_freasons'"'
end

program define _varorder_apply, rclass
    version 16.0
    syntax , NEWORDER(varlist) [EXPECTEDOLD(varlist) INJECTFAIL]
    unab actualold : _all
    if `"`expectedold'"' != "" & `"`actualold'"' != `"`expectedold'"' {
        di as err "varorder: dataset order changed after planning"
        exit 459
    }
    _varorder_assert_permutation, old(`"`actualold'"') new(`"`neworder'"')
    if `"`actualold'"' == `"`neworder'"' {
        return scalar changed = 0
        exit
    }
    quietly _varorder_identity
    local identity `"`r(identity)'"'
    local fr = c(frame)
    capture noisily order `neworder'
    local applyrc = _rc
    if !`applyrc' & "`injectfail'" != "" local applyrc = 459
    if !`applyrc' {
        unab got : _all
        if `"`got'"' != `"`neworder'"' local applyrc = 459
    }
    if `applyrc' {
        capture noisily order `actualold'
        local rollbackrc = _rc
        if `rollbackrc' {
            di as err "varorder: application failed and rollback also failed"
            exit 498
        }
        di as err "varorder: application failed; original order restored"
        exit `applyrc'
    }
    quietly _varorder_identity
    local afteridentity `"`r(identity)'"'
    mata: _varorder_store_undo(st_local("actualold"), st_local("fr"), st_local("afteridentity"))
    return scalar changed = 1
end

program define _varorder_undo, rclass
    version 16.0
    mata: _varorder_fetch_undo()
    if "`__vo_undo_valid'" != "1" {
        di as err "varorder: no valid undo state is available"
        exit 459
    }
    if "`__vo_undo_frame'" != c(frame) {
        di as err "varorder: undo state belongs to another frame"
        exit 459
    }
    quietly _varorder_identity
    if `"`r(identity)'"' != `"`__vo_undo_identity'"' {
        di as err "varorder: current dataset is incompatible with the stored undo state"
        exit 459
    }
    unab current : _all
    _varorder_assert_permutation, old(`"`current'"') new(`"`__vo_undo_order'"')
    capture noisily order `__vo_undo_order'
    if _rc exit _rc
    mata: _varorder_consume_undo()
    local changed = (`"`current'"' != `"`__vo_undo_order'"')
    local k : word count `current'
    local nmove 0
    local maxdisp 0
    forvalues i=1/`k' {
        local v : word `i' of `current'
        local j : list posof "`v'" in __vo_undo_order
        if `i' != `j' {
            local ++nmove
            local d = abs(`i'-`j')
            if `d' > `maxdisp' local maxdisp `d'
        }
    }
    if `changed' di as result "Variable order restored."
    else di as result "Stored variable order was already in place."
    _varorder_returns, oldorder(`"`current'"') neworder(`"`__vo_undo_order'"') k(`k') changed(`changed') ///
        nfdet(0) nfcon(0) nfrel(0) nfamb(0) nfchanged(0) nfsup(0) ///
        nmove(`nmove') maxdisp(`maxdisp')
    return add
end

program define _varorder_assert_permutation
    version 16.0
    syntax , OLD(varlist) NEW(varlist)
    local no : word count `old'
    local nn : word count `new'
    if `no' != `nn' exit 459
    local so : list sort old
    local sn : list sort new
    if `"`so'"' != `"`sn'"' exit 459
    local un : list uniq new
    local nu : word count `un'
    if `nu' != `nn' exit 459
end

program define _varorder_identity, rclass
    version 16.0
    unab names : _all
    local canonical : list sort names
    quietly _datasignature `canonical'
    local sig `"`r(datasignature)'"'
    local meta `"`: data label'|`: sortedby'"'
    foreach v of local canonical {
        local vl : variable label `v'
        local vf : format `v'
        local vv : value label `v'
        local meta `"`meta'|`v'|`vl'|`vf'|`vv'"'
        notes _count nn : `v'
        forvalues j = 1/`nn' {
            notes _fetch one_note : `v' `j'
            local meta `"`meta'|`one_note'"'
        }
    }
    mata: st_local("__vo_metahash", strofreal(hash1(st_local("meta")), "%21x"))
    mata: _varorder_extra_identity(st_local("canonical"))
    return local identity `"`sig'|`__vo_metahash'|`__vo_extra_identity'"'
end

program define _varorder_returns, rclass
    version 16.0
    syntax , OLDORDER(string asis) NEWORDER(string asis) K(integer) CHANGED(integer) ///
        NFDET(integer) NFCON(integer) NFREL(integer) NFAMB(integer) ///
        NFCHANGED(integer) NFSUP(integer) NMOVE(integer) MAXDISP(integer)
    return scalar changed = `changed'
    return scalar k = `k'
    return scalar n_families_detected = `nfdet'
    return scalar n_families_confirmed = `nfcon'
    return scalar n_families_related = `nfrel'
    return scalar n_families_ambiguous = `nfamb'
    return scalar n_families_changed = `nfchanged'
    return scalar n_families_suppressed = `nfsup'
    return scalar n_moved = `nmove'
    return scalar max_displacement = `maxdisp'
    return scalar order_lists_returned = 1
    return local oldorder `"`oldorder'"'
    return local neworder `"`neworder'"'
end

mata:
struct vo_parse {
    string scalar family, system, key, reason
    real scalar temporal, negative, ambiguous
    real rowvector kval
}

string scalar _vo_norm(string scalar raw)
{
    string scalar s
    s = ustrregexra(raw, "([a-z][a-z][a-z])([A-Z])", "$1 $2")
    s = ustrlower(ustrtrim(s))
    s = ustrregexra(s, "[^\p{L}\p{N}]+", " ")
    s = ustrregexra(s, "([[:alpha:]])([0-9])", "$1 $2")
    s = ustrregexra(s, "([0-9])([[:alpha:]])", "$1 $2")
    return(strtrim(ustrregexra(s, " +", " ")))
}

real scalar _vo_has(string scalar s, string scalar re)
{
    return(ustrregexm(" "+s+" ", re))
}

string scalar _vo_clean_family(string scalar s)
{
    string rowvector t, keep
    real scalar i,oka,okb
    t = tokens(s); keep = J(1,0,"")
    for (i=1; i<=cols(t); i++) {
        if (anyof(("a","id","score","scores","measure","measures","measurement","measurements","repeated","assessment","assessments","outcome","outcomes","calendar","year","quarter","grade","academic","term","developmental","within","day","period","then","in","of","for","hierarchy","related","setting","context","location","home","school","community","work","commute","indoor","outdoor","time","wave","visit","t","q","g","questionnaire","item","form","batch","identifier","not","temporal"), t[i])) continue
        if (ustrregexm(t[i], "^[0-9]+$")) continue
        if (anyof(("pre","mid","post","pretest","posttest","baseline","followup","fall","spring","morning","afternoon","evening"),t[i])) continue
        keep = keep,t[i]
    }
    if (cols(keep)==0) {
        if (_vo_has(s," score ")) return("score")
        return("")
    }
    if (cols(keep)==1 & strlen(keep[1])==1) return("")
    return(invtokens(keep))
}

struct vo_parse scalar _vo_parse_source(string scalar raw)
{
    struct vo_parse scalar p
    string scalar s, fam, m
    real scalar n, q, g, d, per, yr
    p.family=""; p.system=""; p.key="."; p.reason=""; p.temporal=0; p.negative=0; p.ambiguous=0; p.kval=J(1,0,.)
    s = _vo_norm(raw)
    if (s=="") return(p)
    p.negative = _vo_has(s, " (not time|not temporal|questionnaire item|assessment form|batch identifier|batch id) ")

    if (ustrregexm(" "+s+" ", " (t|time|wave|visit) 0*([1-9][0-9]*) ")) {
        m=ustrregexs(1); n=strtoreal(ustrregexs(2)); p.temporal=1; p.system=m; p.kval=n; p.key=strofreal(n)
    }
    else if (_vo_has(s," pretest ")) { p.temporal=1; p.system="pretest"; p.kval=1; p.key="1"; }
    else if (_vo_has(s," posttest ")) { p.temporal=1; p.system="pretest"; p.kval=2; p.key="2"; }
    else if (_vo_has(s," baseline ")) { p.temporal=1; p.system="followup"; p.kval=1; p.key="1"; }
    else if (ustrregexm(" "+s+" ", " followup 0*([1-9][0-9]*) ")) { n=strtoreal(ustrregexs(1)); p.temporal=1; p.system="followup"; p.kval=n+1; p.key=strofreal(n+1); }
    else if (_vo_has(s," followup ")) { p.temporal=1; p.system="followup"; p.kval=2; p.key="2"; }
    else if (_vo_has(s," pre ")) { p.temporal=1; p.system="prepost"; p.kval=1; p.key="1"; }
    else if (_vo_has(s," mid ")) { p.temporal=1; p.system="prepost"; p.kval=2; p.key="2"; }
    else if (_vo_has(s," post ")) { p.temporal=1; p.system="prepost"; p.kval=3; p.key="3"; }

    if (ustrregexm(" "+s+" ", " ([12][0-9][0-9][0-9]) q 0*([1-4]) ")) {
        yr=strtoreal(ustrregexs(1)); q=strtoreal(ustrregexs(2)); p.temporal=1; p.system="year_quarter"; p.kval=(yr,q); p.key=strofreal(yr)+":"+strofreal(q)
    }
    else if (ustrregexm(" "+s+" ", " year ([12][0-9][0-9][0-9]) quarter 0*([1-4]) ")) {
        yr=strtoreal(ustrregexs(1)); q=strtoreal(ustrregexs(2)); p.temporal=1; p.system="year_quarter"; p.kval=(yr,q); p.key=strofreal(yr)+":"+strofreal(q)
    }
    else if (ustrregexm(" "+s+" ", " ([12][0-9][0-9][0-9]) quarter 0*([1-4]) ")) {
        yr=strtoreal(ustrregexs(1)); q=strtoreal(ustrregexs(2)); p.temporal=1; p.system="year_quarter"; p.kval=(yr,q); p.key=strofreal(yr)+":"+strofreal(q)
    }
    if (ustrregexm(" "+s+" ", " (g|grade) 0*([1-9][0-9]*) (fall|spring) ")) {
        g=strtoreal(ustrregexs(2)); per=(ustrregexs(3)=="fall" ? 1 : 2); p.temporal=1; p.system="grade_term"; p.kval=(g,per); p.key=strofreal(g)+":"+strofreal(per)
    }
    if (ustrregexm(" "+s+" ", " day 0*([1-9][0-9]*) (morning|afternoon|evening) ")) {
        d=strtoreal(ustrregexs(1)); per=1+(ustrregexs(2)=="afternoon")+2*(ustrregexs(2)=="evening"); p.temporal=1; p.system="day_period"; p.kval=(d,per); p.key=strofreal(d)+":"+strofreal(per)
    }
    if (!p.temporal & ustrregexm(" "+s+" ", " quarter 0*([1-4]) ")) {
        q=strtoreal(ustrregexs(1)); p.temporal=1; p.system="quarter"; p.kval=q; p.key=strofreal(q)
    }
    if (!p.temporal & ustrregexm(" "+s+" ", " ([12][0-9][0-9][0-9]) ")) {
        yr=strtoreal(ustrregexs(1)); p.temporal=1; p.system="year"; p.kval=yr; p.key=strofreal(yr)
    }
    if (!p.temporal & ustrregexm(" "+s+" ", " ([0-9]+) ([0-9]+) ")) {
        p.ambiguous=1; p.system="unknown_hierarchy"; p.key=ustrregexs(1)+":"+ustrregexs(2); p.kval=(strtoreal(ustrregexs(1)),strtoreal(ustrregexs(2)))
    }
    fam=_vo_clean_family(s)
    if (fam=="" & ustrregexm(s,"^([[:alpha:]]+) [0-9]+$")) fam=ustrregexs(1)
    if (!p.temporal & !p.ambiguous & ustrregexm(s,"^(.+) q 0*([1-4])$")) { p.key=strofreal(strtoreal(ustrregexs(2))); p.system="quarter_candidate"; }
    else if (!p.temporal & !p.ambiguous & ustrregexm(s,"^(.+) ([0-9]+)$")) { p.key=strofreal(strtoreal(ustrregexs(2))); p.system="bare_numeric"; }
    if(p.negative & p.system=="year") { p.temporal=0; p.key="."; p.system=""; p.kval=J(1,0,.); }
    p.family=fam
    return(p)
}

real scalar _vo_compatible(string scalar a, string scalar b)
{
    string rowvector ta,tb
    string scalar ia,ib
    real scalar i
    if (a=="" | b=="") return(1)
    if (a==b) return(1)
    if (subinstr(a," ","")==subinstr(b," ","")) return(1)
    if (min((strlen(a),strlen(b)))>=3 & (substr(a,1,strlen(b))==b | substr(b,1,strlen(a))==a)) return(1)
    ta=tokens(a); tb=tokens(b); ia=ib=""
    if(min((strlen(ta[1]),strlen(tb[1])))>=3 & (substr(ta[1],1,strlen(tb[1]))==tb[1] | substr(tb[1],1,strlen(ta[1]))==ta[1])) {
        oka=(cols(ta)==1); okb=(cols(tb)==1)
        if(cols(ta)>1) oka=all((ta[|2\cols(ta)|]:=="at") :| (ta[|2\cols(ta)|]:=="by"))
        if(cols(tb)>1) okb=all((tb[|2\cols(tb)|]:=="at") :| (tb[|2\cols(tb)|]:=="by"))
        if(oka & okb) return(1)
    }
    for(i=1;i<=cols(ta);i++) ia=ia+substr(ta[i],1,1)
    for(i=1;i<=cols(tb);i++) ib=ib+substr(tb[i],1,1)
    if ((strlen(a)>=2 & a==ib) | (strlen(b)>=2 & b==ia)) return(1)
    return(strpos(" "+a+" "," "+b+" ")>0 | strpos(" "+b+" "," "+a+" ")>0)
}

string scalar _vo_schema(string scalar s)
{
    if (anyof(("t","time","wave","visit"),s)) return("index")
    if (anyof(("prepost","pretest"),s)) return("stage")
    if (s=="quarter_candidate") return("quarter")
    if (s=="bare_numeric" | s=="related_lexical" | s=="") return("related")
    return(s)
}

string scalar _vo_sort_key(real rowvector v)
{
    real scalar i
    string rowvector out
    out=J(1,cols(v),"")
    for(i=1;i<=cols(v);i++) out[i]=sprintf("%020.0f",v[i])
    return(invtokens(out,":"))
}

void _varorder_make_plan()
{
    real scalar k,i,j,g,nf,conf,neg,amb,alltemp,collision,gap,pos,newpos,maxd,nmove,nfchanged
    string rowvector vn,fam,grp,state,key,reason,sys,skey,allf,fs,fr,neworder
    real rowvector kval, anchors, ord, members, emitted, classix, idx, gx
    struct vo_parse scalar pn,pl,pt
    k=st_nvar(); vn=J(1,k,""); fam=state=key=reason=sys=skey=J(1,k,""); kval=J(1,k,.)
    for (i=1;i<=k;i++) {
        vn[i]=st_varname(i)
        pn=_vo_parse_source(vn[i]); pl=_vo_parse_source(st_local("__vo_lab"+strofreal(i))); pt=_vo_parse_source(st_local("__vo_note"+strofreal(i)))
        if(ustrregexm(vn[i],"[[:alpha:]][12][0-9][0-9][0-9]")) { pn.temporal=0; pn.key="."; pn.system=""; pn.kval=J(1,0,.); }
        if (ustrregexm(_vo_norm(vn[i]),"^(v|var|x|item|q) [0-9]+$")) pn.family=""
        if (strlen(pn.family)<2) pn.family=""
        if (strlen(pl.family)<2) pl.family=""
        if (strlen(pt.family)<2) pt.family=""
        if (pn.system=="grade_term" & !(_vo_has(_vo_norm(st_local("__vo_lab"+strofreal(i)))," (grade|developmental|academic term) ") | _vo_has(_vo_norm(st_local("__vo_note"+strofreal(i)))," (grade|developmental|academic term) "))) { pn.temporal=0; pn.key="."; pn.kval=J(1,0,.); }
        if (pn.system=="day_period" & !(strpos(_vo_norm(st_local("__vo_lab"+strofreal(i))),"within day") | strpos(_vo_norm(st_local("__vo_note"+strofreal(i))),"within day"))) { pn.temporal=0; pn.key="."; pn.kval=J(1,0,.); }
        conf=0
        if (!_vo_compatible(pn.family,pl.family) | !_vo_compatible(pn.family,pt.family) | !_vo_compatible(pl.family,pt.family)) { conf=1; reason[i]="construct_conflict"; }
        if (pn.temporal & pl.temporal & (pn.key!=pl.key | (pn.system!=pl.system & !(anyof(("t","time","wave","visit"),pn.system) & anyof(("t","time","wave","visit"),pl.system))))) { conf=1; reason[i]="position_conflict"; }
        if (pn.temporal & pt.temporal & pn.key!=pt.key) { conf=1; reason[i]="position_conflict"; }
        if (pl.temporal & pt.temporal & pl.key!=pt.key) { conf=1; reason[i]="position_conflict"; }
        if ((pn.negative|pl.negative|pt.negative) & (pn.temporal|pl.temporal|pt.temporal)) { conf=1; reason[i]="temporal_conflict"; }
        if (!pn.temporal & pl.family!="" & _vo_compatible(pn.family,pl.family)) fam[i]=(pn.family=="" | strlen(pl.family)<=strlen(pn.family) ? pl.family : pn.family)
        else if (pn.family!="") fam[i]=pn.family
        else if (pl.family!="") fam[i]=pl.family
        else fam[i]=pt.family
        if (pl.family!="" & subinstr(fam[i]," ","")==subinstr(pl.family," ","") & strlen(pl.family)<strlen(fam[i])) fam[i]=pl.family
        if (pt.family!="" & subinstr(fam[i]," ","")==subinstr(pt.family," ","") & strlen(pt.family)<strlen(fam[i])) fam[i]=pt.family
        if (pn.temporal) { key[i]=pn.key; sys[i]=pn.system; kval[i]=pn.kval[1]; skey[i]=_vo_sort_key(pn.kval); }
        else if (pl.temporal) { key[i]=pl.key; sys[i]=pl.system; kval[i]=pl.kval[1]; skey[i]=_vo_sort_key(pl.kval); }
        else if (pt.temporal) { key[i]=pt.key; sys[i]=pt.system; kval[i]=pt.kval[1]; skey[i]=_vo_sort_key(pt.kval); }
        if (!pn.temporal & !pl.temporal & !pt.temporal & pn.key!=".") { key[i]=pn.key; sys[i]=pn.system; skey[i]=(pn.system=="quarter_candidate" ? _vo_sort_key(strtoreal(pn.key)) : pn.key); }
        if ((pn.system=="bare_numeric" | pn.system=="quarter_candidate") & (pl.temporal | pt.temporal)) {
            if(pl.temporal) { key[i]=pl.key; sys[i]=pl.system; kval[i]=pl.kval[1]; skey[i]=_vo_sort_key(pl.kval); }
            else { key[i]=pt.key; sys[i]=pt.system; kval[i]=pt.kval[1]; skey[i]=_vo_sort_key(pt.kval); }
        }
        if(ustrregexm(_vo_norm(vn[i]),"^item [0-9]+$") & sys[i]=="time" & fam[i]!="") fam[i]=fam[i]+" time"
        if (!pn.temporal & !pl.temporal & !pt.temporal & strpos(_vo_norm(st_local("__vo_lab"+strofreal(i))),"repeated measure") & ustrregexm(_vo_norm(vn[i])," ([[:alpha:]]+)$")) { key[i]=ustrregexs(1); sys[i]="related_lexical"; skey[i]=key[i]; }
        if (!conf) {
            if (pn.ambiguous|pl.ambiguous|pt.ambiguous) reason[i]="hierarchy_ambiguous"
            else if (pn.negative|pl.negative|pt.negative) reason[i]="explicit_non_temporal"
        }
    }
    grp=fam
    for(i=1;i<=k;i++) if(grp[i]!="") {
        if(reason[i]=="explicit_non_temporal" & sys[i]=="year") grp[i]=grp[i]+"@related"
        else grp[i]=grp[i]+"@"+_vo_schema(sys[i])
    }
    allf=uniqrows(sort(grp',1))'
    if (cols(allf)>0) if (allf[1]=="") allf=select(allf,allf:!="")
    fs=fr=J(1,cols(allf),""); anchors=J(1,cols(allf),.)
    for (g=1;g<=cols(allf);g++) {
        members=select(1..k,grp:==allf[g]); anchors[g]=min(members)
        if (cols(members)<2) { fs[g]="unrelated"; continue; }
        conf=anyof(reason[members],"construct_conflict") | anyof(reason[members],"position_conflict") | anyof(reason[members],"temporal_conflict"); neg=anyof(reason[members],"explicit_non_temporal"); amb=anyof(reason[members],"hierarchy_ambiguous")
        alltemp=all(key[members]:!="") & all(sys[members]:!="bare_numeric") & all(sys[members]:!="related_lexical")
        if(anyof(sys[members],"quarter_candidate")) alltemp=all((sys[members]:=="quarter") :| (sys[members]:=="quarter_candidate")) & anyof(sys[members],"quarter")
        collision=0
        for(i=1;i<cols(members);i++) for(j=i+1;j<=cols(members);j++) if(key[members[i]]!="" & key[members[i]]==key[members[j]]) collision=1
        if(conf) {
            fs[g]="ambiguous"
            if(anyof(reason[members],"construct_conflict")) fr[g]="construct_conflict"
            else if(anyof(reason[members],"position_conflict")) fr[g]="position_conflict"
            else fr[g]="temporal_conflict"
        }
        else if(amb) { fs[g]="ambiguous"; fr[g]="hierarchy_ambiguous"; }
        else if(collision) { fs[g]="ambiguous"; fr[g]="normalized_key_collision"; }
        else if(neg | !alltemp) { fs[g]="related"; fr[g]=(neg ? "explicit_non_temporal" : "temporal_unverified"); }
        else { fs[g]="confirmed"; fr[g]="."; }
        if(fs[g]=="confirmed") {
            gap=0
            if (all((sys[members]:=="t") :| (sys[members]:=="time") :| (sys[members]:=="wave") :| (sys[members]:=="visit"))) {
                if(max(kval[members])-min(kval[members])+1>rows(uniqrows(sort(kval[members]',1)))) gap=1
            }
            if(gap) fr[g]="gap"
        }
        for(i=1;i<=cols(members);i++) { state[members[i]]=fs[g]; if(fr[g]!=".") reason[members[i]]=fr[g]; }
    }
    emitted=J(1,k,0); neworder=J(1,0,"")
    for(pos=1;pos<=k;pos++) {
        gx=select(1..cols(allf),anchors:==pos)
        if(cols(gx)) {
            if(fs[gx[1]]=="confirmed") {
                members=select(1..k,grp:==allf[gx[1]])
                ord=order(skey[members]',1)'
                for(j=1;j<=cols(ord);j++) { neworder=neworder,vn[members[ord[j]]]; emitted[members[ord[j]]]=1; }
            }
        }
        if(!emitted[pos]) { neworder=neworder,vn[pos]; emitted[pos]=1; }
    }
    nmove=0;maxd=0
    for(i=1;i<=k;i++) { newpos=select(1..k,neworder:==vn[i]); if(newpos!=i) { nmove++; maxd=max((maxd,abs(newpos-i))); }; }
    nfchanged=0
    for(g=1;g<=cols(allf);g++) if(fs[g]=="confirmed") { members=select(1..k,grp:==allf[g]); if(any(neworder[members]:!=vn[members])) nfchanged++; }
    classix=select(1..k,state:!="")
    st_local("__vo_new",invtokens(neworder)); st_local("__vo_nfdet",strofreal(sum(fs:!="unrelated")))
    st_local("__vo_nfcon",strofreal(sum(fs:=="confirmed"))); st_local("__vo_nfrel",strofreal(sum(fs:=="related"))); st_local("__vo_nfamb",strofreal(sum(fs:=="ambiguous")))
    st_local("__vo_nfchanged",strofreal(nfchanged)); st_local("__vo_nmove",strofreal(nmove)); st_local("__vo_maxdisp",strofreal(maxd))
    for(i=1;i<=k;i++) { if(reason[i]=="") reason[i]="."; if(key[i]=="") key[i]="."; fam[i]=subinstr(fam[i]," ","_",.); }
    for(i=1;i<=cols(fr);i++) if(fr[i]=="") fr[i]="."
    st_local("__vo_classvars",invtokens(vn[classix])); st_local("__vo_classfams",invtokens(fam[classix])); st_local("__vo_classstates",invtokens(state[classix])); st_local("__vo_classkeys",invtokens(key[classix])); st_local("__vo_classreasons",invtokens(reason[classix]))
    for(i=1;i<=cols(allf);i++) { if(strpos(allf[i],"@")) allf[i]=substr(allf[i],1,strpos(allf[i],"@")-1); allf[i]=subinstr(allf[i]," ","_",.); }
    idx=select(1..cols(allf),fs:!="unrelated"); st_local("__vo_families",invtokens(allf[idx])); st_local("__vo_fstates",invtokens(fs[idx])); st_local("__vo_freasons",invtokens(fr[idx]))
}

void _varorder_store_undo(string scalar ord, string scalar fr, string scalar id)
{
    external string rowvector VARORDER_UNDO_STATE
    VARORDER_UNDO_STATE=(ord,fr,id)
}
void _varorder_fetch_undo()
{
    external string rowvector VARORDER_UNDO_STATE
    if (length(VARORDER_UNDO_STATE)==3) {
        st_local("__vo_undo_valid","1"); st_local("__vo_undo_order",VARORDER_UNDO_STATE[1]); st_local("__vo_undo_frame",VARORDER_UNDO_STATE[2]); st_local("__vo_undo_identity",VARORDER_UNDO_STATE[3])
    }
    else st_local("__vo_undo_valid","0")
}
void _varorder_consume_undo()
{
    external string rowvector VARORDER_UNDO_STATE
    VARORDER_UNDO_STATE=J(1,0,"")
}

void _varorder_extra_identity(string scalar canonical)
{
    string rowvector vars, parts, cn, vln
    string colvector txt
    real colvector val
    real scalar i,j
    vars=tokens(canonical); parts=J(1,0,"")
    for(i=1;i<=cols(vars);i++) {
        if (st_isstrvar(vars[i])) parts=parts,(vars[i]+"="+strofreal(hash1(st_sdata(.,vars[i])),"%21x"))
        else parts=parts,(vars[i]+"="+strofreal(hash1(st_data(.,vars[i])),"%21x"))
    }
    cn=st_dir("char","_dta","*")'
    for(i=1;i<=cols(cn);i++) parts=parts,("_dta["+cn[i]+"]="+st_global("_dta["+cn[i]+"]"))
    for(i=1;i<=cols(vars);i++) {
        cn=st_dir("char",vars[i],"*")'
        for(j=1;j<=cols(cn);j++) parts=parts,(vars[i]+"["+cn[j]+"]="+st_global(vars[i]+"["+cn[j]+"]"))
    }
    vln=vec(st_vldir())'
    vln=select(vln,vln:!="")
    if (cols(vln)) vln=sort(vln',1)'
    for(i=1;i<=cols(vln);i++) {
        st_vlload(vln[i],val,txt)
        parts=parts,("vl="+vln[i]+":"+strofreal(hash1(val),"%21x")+":"+strofreal(hash1(txt),"%21x"))
    }
    st_local("__vo_extra_identity",strofreal(hash1(parts'),"%21x"))
}
end
