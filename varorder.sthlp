{smcl}
{* *! version 1.0.0 21aug2026}{...}
{vieweralsosee "order" "help order"}{...}
{vieweralsosee "notes" "help notes"}{...}

{title:Title}

{phang}
{bf:varorder} {hline 2} Automated detection of temporal structure and ordering of variables using semantic information in variable names, labels, and variable notes{p_end}


{title:Description}

{pstd}
{cmd:varorder} automatically examines the current wide-format dataset, identifies
variables that contain sufficiently clear temporal structure, and places eligible
variables into a defensible temporal order.  Semantic information may come from
variable names, variable labels, variable notes, or agreement across these
sources.{p_end}

{pstd}
The command is designed to reduce the manual work required to locate scattered
repeated-measure variables, determine their temporal sequence, and reorganize
them safely.  When the available information is ambiguous or conflicting,
{cmd:varorder} reports the issue rather than guessing.{p_end}


{title:Why use varorder?}

{pstd}
Stata's native {cmd:order} command is effective when the user already knows
exactly which variables should move and where they should go.  In large
wide-format datasets, however, the difficult part may be identifying which
variables belong to the same repeated-measure structure and determining their
correct temporal sequence.  {cmd:varorder} automates that detection step and
then performs the corresponding variable ordering when the evidence is
sufficiently clear.{p_end}


{title:Key features}

{p 4 6 2}• {bf:Semantic detection from three metadata sources.} {cmd:varorder} uses semantic information in variable names, variable labels, and variable notes to identify variables that belong together and determine whether they contain a defensible temporal structure. Evidence may come from one source or from agreement across multiple sources.{p_end}

{p 4 6 2}• {bf:Temporal and hierarchical ordering.} The command recognizes high-confidence temporal patterns such as {cmd:T1/T2/T3}, {cmd:Wave 1/2/3}, {cmd:Visit 1/2/3}, explicit calendar years, and sequences such as {cmd:pre < mid < post}. When multiple ordered temporal components are supported by the semantic information, {cmd:varorder} can use hierarchical keys such as {cmd:year > quarter}, {cmd:grade > term}, or {cmd:day > within-day period}. Bare numeric suffixes are not treated as temporal unless the available semantics support that interpretation.{p_end}

{p 4 6 2}• {bf:Metadata normalization across names, labels, and notes.} Formatting inconsistencies such as capitalization, separators, compact forms, and leading zeros may occur in any metadata source. {cmd:varorder} normalizes such differences internally for detection while preserving the original variable names, labels, and notes and retaining each source separately so that agreement and conflict remain detectable.{p_end}

{p 4 6 2}• {bf:Dataset safety.} {cmd:varorder} acts only when temporal evidence is sufficiently clear. Related but non-temporal variables, semantically insufficient numeric sequences, ambiguous hierarchical structures, normalized-key collisions, and metadata conflicts are reported for review rather than guessed into an order. The command is preview-first, proposes one complete ordering plan, asks for at most one confirmation, and changes only the physical order of variables.{p_end}


{title:Syntax}

{p 4 22 2}{cmd:varorder}{space 3}automatically detects and orders all variables that meet the temporal-ordering requirements.{p_end}
{p 4 22 2}{cmd:varorder, undo}{space 3}restores the variable order that existed immediately before the most recent successful {cmd:varorder} operation.{p_end}


{title:Practical applications}

{title:Example 1. Preview, review, and apply}

{pstd}
The following transcript is from the supplied
{cmd:varorder_example_data.dta}.  It is actual validated output from
StataNow/MP 19.5; the counts are not illustrative placeholders.{p_end}

{p 4 4 2}{cmd:. use "D:/varorder/varorder_example_data.dta", clear}{p_end}
{p 4 4 2}{cmd:. varorder}{p_end}

{p 8 8 2}{txt:varorder preview summary}{p_end}
{p 8 8 2}{txt:  Examined: 100 variables; candidate structures: 28}{p_end}
{p 8 8 2}{txt:  Confirmed: 18; stems: alg, anxiety, bp, depression, health, math (3), memory_time, mobility, read, reading, sales, score (+3 stems omitted)}{p_end}
{p 8 8 2}{txt:  Gap warning - ordering allowed (1): mobility: missing indexed position}{p_end}
{p 8 8 2}{txt:  Related/unverified - no action (5): eng: non-temporal meaning established; exercise: temporal meaning unverified; lab: non-temporal meaning established; mood: temporal meaning unverified; reading: non-temporal meaning established}{p_end}
{p 8 8 2}{txt:  Ambiguous/conflicting - no action (5): focus: construct conflict; memory: metadata conflict; pain: normalized-key collision; score: construct conflict; survey: metadata conflict}{p_end}
{p 8 8 2}{txt:  Proposed: 18 structures; 98 variables; maximum displacement 90 columns}{p_end}

{p 8 8 2}{txt:If you want to proceed, please press Enter.}{p_end}

{pstd}
After the user reviews the one summary and presses Enter, the already frozen
plan is applied once.  The command then prints only the following postview
summary:{p_end}

{p 8 8 2}{txt:varorder postview summary}{p_end}
{p 8 8 2}{txt:  Updated: yes; examined 100; reorganized 18; moved 98; maximum displacement 90 columns}{p_end}

{pstd}
Ordinary confirmed structures are summarized by count and normalized stem.
Only cases needing attention are explained.  Related or ambiguous structures
are reported as {it:no action}, and no variable-by-variable position listing is
printed.  The bounded display does not truncate the frozen full permutation.{p_end}


{title:Example 2. Undo the most recent ordering}

{pstd}
After a successful mutating {cmd:varorder}, restore the immediately preceding
physical variable order with:{p_end}

{p 4 4 2}{cmd:. varorder, undo}{p_end}

{pstd}
Undo is single-level.  A successful undo consumes the saved state.  A declined
preview, a no-op, or a failed operation does not replace an existing valid undo
state.  Undo refuses safely if the stored state does not belong to the current
compatible dataset state.{p_end}


{title:Stored results}

{pstd}
After {cmd:varorder}, the command stores the following in {cmd:r()}:{p_end}

{synoptset 34 tabbed}{...}
{synopt:{cmd:r(changed)}}1 if physical variable order changed; 0 otherwise{p_end}
{synopt:{cmd:r(k)}}number of variables examined{p_end}
{synopt:{cmd:r(n_families_detected)}}number of candidate structures detected{p_end}
{synopt:{cmd:r(n_families_confirmed)}}number of confirmed temporal structures{p_end}
{synopt:{cmd:r(n_families_related)}}number of related or temporally unverified structures{p_end}
{synopt:{cmd:r(n_families_ambiguous)}}number of ambiguous or conflicting structures{p_end}
{synopt:{cmd:r(n_families_changed)}}number of confirmed structures proposed for reorganization{p_end}
{synopt:{cmd:r(n_families_suppressed)}}sum of related and ambiguous structures{p_end}
{synopt:{cmd:r(n_moved)}}number of variables whose physical positions changed{p_end}
{synopt:{cmd:r(max_displacement)}}largest position displacement among moved variables{p_end}
{synopt:{cmd:r(order_lists_returned)}}1 when complete order lists are returned{p_end}
{synopt:{cmd:r(oldorder)}}complete pre-command physical variable order{p_end}
{synopt:{cmd:r(neworder)}}complete resulting physical variable order{p_end}


{title:Compatibility}

{pstd}
{cmd:varorder} requires Stata 16 or later.  This release was developed and
validated with StataNow/MP 19.5.{p_end}


{title:Author}

{pstd}
Hao Ma, Ph.D.{p_end}

{pstd}
Email: {browse "mailto:shouhuoxiwang2027@gmail.com":shouhuoxiwang2027@gmail.com}{p_end}


{title:Citation}

{pstd}
If you use {cmd:varorder} in research, please cite the software.  Before an
SSC/RePEc identifier is assigned, the suggested citation is:{p_end}

{phang}
Ma, H. (2026). {it:varorder: Automated semantic detection and temporal ordering of variables in Stata}. Stata module, version 1.0.0.{p_end}


{title:License}

{pstd}
{cmd:varorder} is free software licensed under the GNU General Public License version 3 (GPL-3.0). A copy of the GNU General Public License version 3 should be distributed with the {cmd:varorder} package.{p_end}
