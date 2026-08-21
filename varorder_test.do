version 16.0

/*
    Public release acceptance test for varorder 1.0.0.

    Usage from the project root:
        do varorder_test.do

    Optional first argument:
        do varorder_test.do "D:/path/to/varorder"

    This compact entry point validates the installed release artifacts and a
    representative end-to-end subset.  The larger frozen Gate 3--7 suites are
    retained under tests/ for exhaustive and adversarial validation.
*/

args project_root
clear all
set more off
set matalnum on
capture log close

if `"`project_root'"' == "" local project_root `"`c(pwd)'"'
local project_root = subinstr(`"`project_root'"', "\", "/", .)
while substr(`"`project_root'"', -1, 1) == "/" {
    local project_root = substr(`"`project_root'"', 1, strlen(`"`project_root'"')-1)
}

log using `"`project_root'/varorder_test.log"', text replace

scalar TV_tests = 0
scalar TV_pass = 0
scalar TV_fail = 0

program define tvassert
    syntax anything(name=expr equalok)
    scalar TV_tests = TV_tests + 1
    capture assert `expr'
    if _rc {
        scalar TV_fail = TV_fail + 1
        di as error "TEST_VARORDER_ASSERTION_FAILED: `expr'"
    }
    else scalar TV_pass = TV_pass + 1
end

capture confirm file `"`project_root'/varorder.ado"'
local artifact_rc = _rc
tvassert `artifact_rc' == 0
capture confirm file `"`project_root'/varorder.sthlp"'
local artifact_rc = _rc
tvassert `artifact_rc' == 0

adopath ++ `"`project_root'"'
quietly do `"`project_root'/varorder.ado"'
capture which varorder
local which_rc = _rc
tvassert `which_rc' == 0

* The public syntax is deliberately limited to the two documented forms.
clear
set obs 1
generate byte placeholder = 1
capture noisily varorder placeholder
local syntax_rc = _rc
tvassert `syntax_rc' == 198
capture noisily varorder, reverse
local syntax_rc = _rc
tvassert `syntax_rc' == 198

* Help-file example plus protected-state, preview, no-op, and undo checks.
clear
set obs 4
generate double fatigue_t3 = _n + 30
replace fatigue_t3 = .a in 2
generate long identifier = _n
generate strL narrative = cond(mod(_n,2), "中文记录—alpha", "")
generate double fatigue_t1 = _n + 10
replace fatigue_t1 = . in 3
generate double fatigue_t2 = _n + 20
format identifier %08.0f
label define identifier_vl 1 "one" 2 "two" 3 "three" 4 "four"
label values identifier identifier_vl
label variable identifier "Observation identifier"
notes identifier: Protected non-temporal identifier note
char identifier[role] "identifier"
char _dta[test_source] "varorder_test.do"
sort identifier
tsset identifier

local example_old "fatigue_t3 identifier narrative fatigue_t1 fatigue_t2"
local example_new "fatigue_t1 fatigue_t2 fatigue_t3 identifier narrative"
unab observed_old : _all
tvassert `"`observed_old'"' == `"`example_old'"'
quietly _varorder_identity
local protected_before `"`r(identity)'"'

capture log close tvpreview
log using `"`project_root'/varorder_test_preview.log"', text replace name(tvpreview)
noisily varorder
local preview_changed = r(changed)
log close tvpreview
unab after_preview : _all
tvassert `"`after_preview'"' == `"`example_old'"'
tvassert `preview_changed' == 0

file open tvp using `"`project_root'/varorder_test_preview.log"', read text
local preview_headers = 0
local preview_prompts = 0
file read tvp line
while r(eof) == 0 {
    if strpos(`"`line'"', "varorder preview summary") local ++preview_headers
    if strpos(`"`line'"', "If you want to proceed, please press Enter.") local ++preview_prompts
    file read tvp line
}
file close tvp
tvassert `preview_headers' == 1
tvassert `preview_prompts' == 1

quietly _varorder_plan
local planned_old `r(oldorder)'
local planned_new `r(neworder)'
tvassert `"`planned_old'"' == `"`example_old'"'
tvassert `"`planned_new'"' == `"`example_new'"'
tvassert r(n_families_confirmed) == 1
tvassert r(n_moved) == 5
capture noisily _varorder_assert_permutation, old(`"`planned_old'"') new(`"`planned_new'"')
local permutation_rc = _rc
tvassert `permutation_rc' == 0

* Gate 6 separately validates a real interactive yes.  Here the already-frozen
* plan is applied through the same production transaction routine so that the
* compact test remains deterministic in batch execution.
quietly _varorder_apply, neworder(`planned_new') expectedold(`planned_old')
local applied_changed = r(changed)
tvassert `applied_changed' == 1
unab after_apply : _all
tvassert `"`after_apply'"' == `"`example_new'"'
quietly _varorder_identity
local protected_after `"`r(identity)'"'
mata: st_numscalar("__tv_identity_equal", st_local("protected_before")==st_local("protected_after"))
tvassert __tv_identity_equal == 1

capture log close tvnoop
log using `"`project_root'/varorder_test_noop.log"', text replace name(tvnoop)
noisily varorder
local noop_changed = r(changed)
log close tvnoop
tvassert `noop_changed' == 0
unab after_noop : _all
tvassert `"`after_noop'"' == `"`example_new'"'
file open tvn using `"`project_root'/varorder_test_noop.log"', read text
local noop_prompts = 0
file read tvn line
while r(eof) == 0 {
    if strpos(`"`line'"', "If you want to proceed, please press Enter.") local ++noop_prompts
    file read tvn line
}
file close tvn
tvassert `noop_prompts' == 0

capture noisily varorder, undo
local undo_rc = _rc
local undo_changed = r(changed)
tvassert `undo_rc' == 0
tvassert `undo_changed' == 1
unab after_undo : _all
tvassert `"`after_undo'"' == `"`example_old'"'
quietly _varorder_identity
local protected_undo `"`r(identity)'"'
mata: st_numscalar("__tv_undo_identity_equal", st_local("protected_before")==st_local("protected_undo"))
tvassert __tv_undo_identity_equal == 1
capture noisily varorder, undo
local undo2_rc = _rc
tvassert `undo2_rc' == 459

* Label-only inference; silence in names and notes is not conflict.
clear
set obs 2
generate byte shard_b = _n
generate byte shard_a = _n
label variable shard_b "Resilience posttest"
label variable shard_a "Resilience pretest"
quietly _varorder_plan
tvassert `"`r(neworder)'"' == "shard_a shard_b"
tvassert r(n_families_confirmed) == 1
tvassert r(n_families_ambiguous) == 0

* Note-only inference.
clear
set obs 2
generate byte node_b = _n
generate byte node_a = _n
notes node_b: Persistence followup
notes node_a: Persistence baseline
quietly _varorder_plan
tvassert `"`r(neworder)'"' == "node_a node_b"
tvassert r(n_families_confirmed) == 1

* Dirty case, separator, and leading-zero normalization is internal only.
clear
set obs 2
generate byte kinetic_t03 = _n
generate byte KINETIC_T1 = _n
generate byte kiNetic_t_2 = _n
quietly _varorder_plan
tvassert `"`r(neworder)'"' == "KINETIC_T1 kiNetic_t_2 kinetic_t03"
tvassert r(n_families_confirmed) == 1
local dirty_names `r(neworder)'
tvassert `"`dirty_names'"' == "KINETIC_T1 kiNetic_t_2 kinetic_t03"

* Indexed gaps warn but observed positions remain sortable.
clear
set obs 2
generate byte canopy_t4 = _n
generate byte divider = _n
generate byte canopy_t1 = _n
quietly _varorder_plan
tvassert `"`r(neworder)'"' == "canopy_t1 canopy_t4 divider"
tvassert `"`r(family_reasons)'"' == "gap"
tvassert r(n_families_confirmed) == 1

* Supported year > quarter hierarchy.
clear
set obs 2
generate byte crop_2024_q2 = _n
generate byte flag = _n
generate byte crop_2023_q4 = _n
generate byte crop_2024_q1 = _n
quietly _varorder_plan
tvassert `"`r(neworder)'"' == "crop_2023_q4 crop_2024_q1 crop_2024_q2 flag"
tvassert r(n_families_confirmed) == 1

* A normalized-key collision suppresses only its own group.
clear
set obs 2
generate byte mistral_t2 = _n
generate byte orchid_t2 = _n
generate byte mistral_t01 = _n
generate byte orchid_t1 = _n
generate byte mistral_t1 = _n
generate byte tail = _n
quietly _varorder_plan
tvassert `"`r(neworder)'"' == "mistral_t2 orchid_t1 orchid_t2 mistral_t01 mistral_t1 tail"
tvassert r(n_families_confirmed) == 1
tvassert r(n_families_ambiguous) == 1
tvassert r(n_families_suppressed) == 1

* Temporal-looking names contradicted by explicit non-temporal notes are not moved.
clear
set obs 2
generate byte citron_t2 = _n
generate byte citron_t1 = _n
label variable citron_t2 "Citron Time 2"
label variable citron_t1 "Citron Time 1"
notes citron_t2: Citron questionnaire item 2
notes citron_t1: Citron questionnaire item 1
quietly _varorder_plan
tvassert `"`r(neworder)'"' == "citron_t2 citron_t1"
tvassert r(n_families_confirmed) == 0
tvassert r(n_families_ambiguous) == 1

* Non-temporal numeric suffixes are not guessed into temporal order.
clear
set obs 2
generate byte parcelcode8 = _n
generate byte parcelcode7 = _n
quietly _varorder_plan
tvassert `"`r(neworder)'"' == "parcelcode8 parcelcode7"
tvassert r(n_families_confirmed) == 0

di as result "TEST_VARORDER_TESTS=" TV_tests
di as result "TEST_VARORDER_PASS=" TV_pass
di as result "TEST_VARORDER_FAIL=" TV_fail

local final_fail = TV_fail
log close
if `final_fail' > 0 exit 9
exit, clear

