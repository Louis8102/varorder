# Changelog

All notable public changes to `varorder` are documented in this file.

## [2.0.0] - 2026-08-31

- Replaced separate family-specific comparison paths with one conservative
  temporal-component and precedence-constraint engine.
- Added additional validated English calendar-date surfaces, including
  `Jan 2, 2026` and `2 January 2026`, while continuing to refuse ambiguous
  MDY/DMY numeric dates unless the same variable's metadata declares the order.
- Added explicit precedence relations for otherwise unknown semantic stages;
  movement requires one strict, cycle-free, uniquely determined order.
- Strengthened source-aware evidence fusion across variable names, labels,
  notes, and attached value-label metadata, including opaque variable names.
- Added conservative detection of cycles, non-unique orders, incompatible
  references, hierarchy ambiguity, invalid temporal values, and cross-unit
  comparisons.
- Added concise, self-identifying family- and variable-level audit results
  without new user syntax. Temporal types, evidence sources, inferred keys, and
  no-action reasons are returned as readable text; partial results are never
  silently truncated.
- Expanded the single public example dataset from 146 to 272 variables by
  adding 126 independently specified V2 cases; production code does not read
  their expected classifications.
- Preserved the compact preview, one-Enter confirmation, physical-order-only
  mutation, transactional rollback, compatible-state-checked single-level undo,
  indexed-gap ordering, and existing public stored results.

## [1.1.0] - 2026-08-23

- Added a typed temporal-component model with explicit compatibility and
  precedence checks; the ordinary syntax remains `varorder` and
  `varorder, undo`.
- Added conservative support for explicitly marked calendar months, valid ISO
  calendar dates, fiscal year/quarter, academic year/indexed term, extended
  observation stages, treatment cycle/visit, calendar year/quarter/month, and
  signed relative hour/day/week.
- Added calendar-validity and leap-year checks, quarter/month consistency
  checks, numeric signed-time sorting, and refusal to compare incompatible
  temporal systems.
- Preserved existing gap behavior: indexed gaps warn but remain orderable, while
  nonconsecutive dates and relative times do not imply missing planned visits.
- Consolidated all original and version 1.1.0 demonstrations into the single
  public `varorder_example_data.dta` fixture.
- Fixed the public `r(oldorder)` and `r(neworder)` transport so both results are
  complete directly executable Stata varlists without literal compound-quote
  delimiters.
- Retained the compact preview, one-Enter confirmation, transactional ordering,
  protected-state invariants, and single-level compatible-state-checked undo.

## [1.0.0] - 2026-08-21

Initial public release.

- Declared Stata 16 or later as the minimum runtime; development and automated
  validation used StataNow/MP 19.5.
- Added automatic temporal-family inference from variable names, variable
  labels, variable notes, and attached value-label metadata. Value labels are
  used conservatively as value-domain/construct evidence and never by
  themselves as a variable-level time position.
- Added a general English stage model supporting defensible structures such as
  baseline, during treatment, and follow-up without construct-specific rules.
- Added conservative ordinary and hierarchical temporal ordering.
- Added internal normalization without permanent metadata changes.
- Added suppression for ambiguity, material metadata conflicts, and normalized
  temporal-key collisions.
- Added indexed-gap warnings that retain safe ordering of observed positions.
- Added a bounded preview, one Enter confirmation, and the single successful
  completion line `Variable order updated.`; no postview heading or repeated
  statistics are printed after application. The confirmation text is displayed
  before Stata waits for Enter.
- Added single-level, compatible-state-checked undo.
- Added transactional permutation validation, rollback, protected-state checks,
  independent unit/adversarial fixtures, and mutation testing.
