{smcl}
{* *! version 2.0.0 31aug2026}{...}
{vieweralsosee "order" "help order"}{...}
{vieweralsosee "notes" "help notes"}{...}

{title:Title}

{phang}
{bf:varorder} {hline 2} Automated detection of temporal structure and ordering of variables
using semantic information in variable names, labels, variable notes, and attached value labels{p_end}


{title:Description}

{pstd}
This module automatically examines the current wide-format dataset, identifies variables with
sufficiently clear temporal structure using semantic information from variable names, variable
labels, variable notes, attached value-label metadata, or agreement across these sources. It
represents supported time expressions as temporal components, combines them with defensible
precedence relations, and moves a family only when the resulting order is unique and conflict-free.
When the available information is ambiguous, incomplete, or conflicting,
{cmd:varorder} reports the issue rather than guessing.{p_end}


{title:Why use varorder?}

{pstd}
Stata's native {cmd:order} command is effective when the user already knows
exactly which variables should move and where they should go.  In large
wide-format datasets, however, the difficult part may be identifying which
variables belong to the same repeated-measure structure and determining their
correct temporal sequence.  {cmd:varorder} is designed to reduce the manual
work required to locate scattered repeated-measure variables, determine their
temporal sequence, and reorganize them safely. Version 2.0.0 applies one common
decision framework across supported indexes, stages, dates, relative times, and
hierarchies, so ordinary users do not need to select a pattern or learn new
options as metadata conventions vary across datasets.{p_end}


{title:Key features}

{p 4 6 2}• {bf:Semantic detection from four sources.} {cmd:varorder} uses semantic
information in variable names, variable labels, variable notes, and attached value-label metadata
to identify variables that belong together and determine whether they contain a defensible
temporal structure. Value labels provide value-domain evidence; their category text is not treated
as a variable's measurement occasion.{p_end}

{p 4 6 2}• {bf:General temporal-component ordering.} The command recognizes high-confidence
temporal patterns such as {cmd:T1/T2/T3}, {cmd:Wave 1/2/3}, {cmd:Visit 1/2/3}, explicit calendar
years, and sequences such as {cmd:pre < mid < post} and
{cmd:screening < baseline < during treatment < discharge < follow-up}. It also supports explicitly
marked calendar months, validated calendar dates, fiscal year/quarter, academic year/indexed term,
{cmd:cycle > visit}, {cmd:year > quarter > month}, and signed relative hour/day/week expressions.
Different supported forms enter one common comparison system. When multiple ordered temporal
components are supported by the semantic information, {cmd:varorder} uses only unambiguous
precedence. Bare numeric suffixes are not treated as
temporal unless the available semantics support that interpretation.{p_end}

{p 4 6 2}• {bf:Constraint-based semantic stages.} Supported stage sequences are ordered directly.
Other stage words are used only when the metadata explicitly supplies relations such as
{cmd:enrollment < induction < maintenance < discharge}. Cycles, disconnected relations, or more
than one possible order cause no action.{p_end}

{p 4 6 2}• {bf:Conservative date interpretation.} Supported unambiguous forms include
{cmd:2026-01-02}, {cmd:2026/01/02}, {cmd:Jan 2, 2026}, and {cmd:2 January 2026}.
Numeric dates such as {cmd:01-02-2026} or {cmd:1/2/2026} are not guessed when both MDY and DMY
are possible; they require an explicit convention in the same variable's metadata. Calendar
validity is checked, and two-digit years are not interpreted.{p_end}

{p 4 6 2}• {bf:Metadata normalization across semantic sources.} Formatting inconsistencies
such as capitalization, separators, compact forms, and zero-padding in temporal indexes
(for example, {cmd:T03} versus {cmd:T3}) may occur in any metadata
source. {cmd:varorder} normalizes such differences internally for detection while preserving the
original variable names, labels, notes, and attached value labels and retaining each source separately so that agreement
and conflict remain detectable.{p_end}

{p 4 6 2}• {bf:Auditable decisions without additional syntax.} The default screen output remains
compact. Advanced users can inspect aligned {cmd:r()} results for each detected structure and
member variable, including its decision, temporal schema, evidence sources, normalized key, and
warning or no-action reason.{p_end}

{p 4 6 2}• {bf:Dataset safety.} {cmd:varorder} acts only when temporal evidence is sufficiently
clear. Related but non-temporal variables and semantically insufficient numeric sequences remain
unchanged. Hierarchy ambiguity, normalized-key collisions, metadata conflicts, invalid time values,
cycles, and non-unique constraint orders are reported for review
rather than guessed into an order. The command is preview-first, proposes one complete ordering
plan, asks for at most one confirmation, and changes only the physical order of variables. An
indexed gap produces a warning but does not by itself prevent ordering when the observed sequence
is otherwise unambiguous.{p_end}


{title:Syntax}

{p 4 22 2}{cmd:varorder}{p_end}
{p 4 22 2}{cmd:varorder, undo}{p_end}


{title:Practical applications}

{title:Example 1. Use the module to automatically detect temporal families and order their variables in the provided example dataset}

{pstd}
The supplied dataset contains 5,000 observations and 272 variables. It retains the 146-variable
example used through version 1.1.0 and adds 126 independently specified version 2.0.0 variables
covering generalized temporal components, explicit stage constraints, additional calendar-date
surfaces, deep hierarchies, source conflicts, cycles, non-unique orders, and conservative no-action
controls.{p_end}

{p 4 4 2}{cmd:. use varorder_example_data.dta, clear}{p_end}
{p 4 4 2}{cmd:. varorder}{p_end}

{p 8 8 2}{txt:varorder preview summary}{p_end}

{p 8 8 2}{txt:Examined: 272 variables}{p_end}
{p 8 8 2}{txt:Confirmed temporal structures: 48}{p_end}
{p 8 8 2}{txt:Variables to be reordered: 186}{p_end}
{p 8 8 2}{txt:Maximum displacement: 89 columns}{p_end}

{p 8 8 2}{txt:Issues requiring review:}{p_end}
{p 10 10 2}{txt:Gap warnings but ordering allowed (3): fortitude, mobility, vigor}{p_end}
{p 10 10 2}{txt:Related/unverified — no action (14): barcode, batchcode, chronological_comfort, eng, exercise, lab, moduleitem, mood, ...}{p_end}
{p 10 10 2}{txt:Ambiguous/conflicting — no action (20): acoustic_calibration, apex, decision_confidence, finance, focus, memory, mirage, motor_coordination, ...}{p_end}

{p 8 8 2}{txt:All eligible structures will be included in the proposed ordering.}
{txt:Structures marked as no action will remain unchanged.}{p_end}

{p 8 8 2}{txt: }{p_end}
{p 8 8 2}{txt:Press Enter to apply the proposed ordering.}{p_end}

{p 8 8 2}{txt:Variable order updated.}{p_end}


{title:Example 2. Undo the most recent ordering}

{pstd}
After a successful mutating {cmd:varorder}, restore the immediately preceding
physical variable order with:{p_end}

{p 4 4 2}{cmd:. varorder, undo}{p_end}


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
{synopt:{cmd:r(n_families_changed)}}number of confirmed structures contributing to changed positions{p_end}
{synopt:{cmd:r(n_families_suppressed)}}sum of related and ambiguous structures{p_end}
{synopt:{cmd:r(families_detected)}}identifiers of candidate structures detected{p_end}
{synopt:{cmd:r(families_confirmed)}}identifiers of confirmed temporal structures{p_end}
{synopt:{cmd:r(families_related)}}identifiers of related or temporally unverified structures{p_end}
{synopt:{cmd:r(families_ambiguous)}}identifiers of ambiguous or conflicting structures{p_end}
{synopt:{cmd:r(families_changed)}}identifiers of confirmed structures contributing to changed positions{p_end}
{synopt:{cmd:r(families_suppressed)}}identifiers of related and ambiguous structures{p_end}
{synopt:{cmd:r(n_moved)}}number of variables whose physical positions changed{p_end}
{synopt:{cmd:r(max_displacement)}}largest position displacement among moved variables{p_end}
{synopt:{cmd:r(order_lists_returned)}}1 when complete order lists are returned{p_end}
{synopt:{cmd:r(oldorder)}}complete pre-command physical variable order, directly usable as a varlist{p_end}
{synopt:{cmd:r(neworder)}}complete resulting physical variable order, directly usable as a varlist{p_end}
{synopt:{cmd:r(audit_lists_returned)}}1 when every aligned audit list is returned completely; 0 otherwise{p_end}
{synopt:{cmd:r(audit_family_ids)}}unique encoded family identifiers{p_end}
{synopt:{cmd:r(audit_family_names)}}encoded normalized family names, aligned with {cmd:r(audit_family_ids)}{p_end}
{synopt:{cmd:r(audit_family_states)}}encoded decisions, aligned with {cmd:r(audit_family_ids)}{p_end}
{synopt:{cmd:r(audit_family_types)}}encoded temporal types and schemas, aligned with {cmd:r(audit_family_ids)}{p_end}
{synopt:{cmd:r(audit_family_evidence)}}encoded evidence sources, aligned with {cmd:r(audit_family_ids)}{p_end}
{synopt:{cmd:r(audit_family_reasons)}}encoded warning or no-action reasons, aligned with {cmd:r(audit_family_ids)}{p_end}
{synopt:{cmd:r(audit_variables)}}encoded variable names for variable-level audit results{p_end}
{synopt:{cmd:r(audit_variable_family_ids)}}encoded family identifiers, aligned with {cmd:r(audit_variables)}{p_end}
{synopt:{cmd:r(audit_variable_keys)}}encoded temporal keys, aligned with {cmd:r(audit_variables)}{p_end}
{synopt:{cmd:r(audit_variable_evidence)}}encoded evidence sources, aligned with {cmd:r(audit_variables)}{p_end}
{synopt:{cmd:r(audit_variable_reasons)}}encoded warning or no-action reasons, aligned with {cmd:r(audit_variables)}{p_end}

{pstd}
The aligned audit locals use one whitespace-delimited token per field. A nonempty field is the
complete result of {cmd:ustrtohex()} applied to the original Unicode text; {cmd:~} represents an
empty field. Decode a nonempty token with {cmd:ustrunescape()}. If complete aligned audit lists
cannot be returned safely within Stata's macro limits, {cmd:r(audit_lists_returned)} is 0 and all
aligned audit locals are empty; counts and the established stored results remain available.{p_end}


{title:Compatibility}

{pstd}
{cmd:varorder} requires Stata 16 or later. Version 2.0.0 was developed and validated with
StataNow/MP 19.5; no broader development-environment claim is made.{p_end}


{title:Version history}

{pstd}
2.0.0, 31 August 2026. Replaced form-by-form family comparison with a common
temporal-component and precedence-constraint engine. Added additional validated English
calendar-date forms, explicit ordering for otherwise unknown semantic stages, stronger cross-source
evidence fusion, conservative cycle and non-unique-order suppression, and complete aligned family-
and variable-level audit results. Expanded the single example dataset from 146 to 272 variables by
adding 126 independent V2 cases. The ordinary syntax, compact preview, single confirmation,
physical-order-only mutation, rollback, and single-level undo remain unchanged.{p_end}

{pstd}
1.1.0, 23 August 2026. Added a typed temporal-component model and conservative
support for calendar months, valid ISO dates, fiscal year/quarter, academic
year/indexed term, extended observation stages, cycle/visit,
year/quarter/month, and signed relative time. The ordinary syntax, conservative
no-action rules, one-confirmation workflow, data and metadata preservation, and
single-level undo remain unchanged. Complete returned order lists are directly
usable as Stata varlists.{p_end}

{pstd}
1.0.0, 21 August 2026. Initial SSC release for automatic semantic detection
and safe temporal ordering from variable names, variable labels, variable
notes, and attached value-label metadata.{p_end}


{title:Author}

{pstd}
Hao Ma, Ph.D.{p_end}

{pstd}
Email: {browse "mailto:shouhuoxiwang2027@gmail.com":shouhuoxiwang2027@gmail.com}{p_end}


{title:Suggested citation}

{phang}
Hao Ma, 2026. "{browse "https://ideas.repec.org/c/boc/bocode/s459871.html":VARORDER: Stata module for automatic semantic temporal ordering of variables in wide-format Stata datasets}", {browse "https://ideas.repec.org/s/boc/bocode.html":Statistical Software Components} S459871, Boston College Department of Economics.{p_end}


{title:License}

{pstd}
{cmd:varorder} is free software licensed under the GNU General Public License version 3
(GPL-3.0).{p_end}
