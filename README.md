# varorder

`varorder` is a Stata module for automatically detecting temporal structure and
reordering eligible variables in wide-format datasets. It uses semantic
information from variable names, variable labels, variable notes, and attached
value-label metadata, while
leaving ambiguous, conflicting, and non-temporal structures unchanged.

The ordinary workflow is deliberately simple:

```stata
varorder
```

To restore the physical variable order that preceded the most recent successful
mutating run:

```stata
varorder, undo
```

## Why varorder?

Stata's native `order` command works well when the desired variable list and
positions are already known. In a large wide-format dataset, the harder task is
often finding scattered repeated-measure variables and reconstructing their
temporal sequence. `varorder` performs that inference conservatively and applies
only a complete, validated permutation.

## Installation and example data

Install the current release directly from GitHub:

```stata
net install varorder, from("https://raw.githubusercontent.com/Louis8102/varorder/main") replace
```

Retrieve the example dataset and the example and test do-files:

```stata
net get varorder, from("https://raw.githubusercontent.com/Louis8102/varorder/main") replace
```

Load the comprehensive example dataset:

```stata
use varorder_example_data.dta, clear
```

Open the help file:

```stata
help varorder
```

Project repository: [github.com/Louis8102/varorder](https://github.com/Louis8102/varorder)

## Practical example

The repository includes one comprehensive `varorder_example_data.dta`: a
5,000-observation, 146-variable development and demonstration dataset with
shuffled temporal families, metadata conflicts, gaps, collisions,
Unicode/string fixtures, and system and extended missing values.

The final six variables specifically demonstrate the fourth semantic source.
`x345`, `x900`, and `x1000` share the distinctive `marital_status` value domain,
while their notes supply follow-up, baseline, and during-treatment positions;
the proposed relative order is therefore `x900 x1000 x345`. `x930`, `x710`, and
`x820` share the `promotion_status` value domain but contain no variable-level
time evidence, so they are reported as related/unverified and are not
temporally sorted.

The same comprehensive dataset also demonstrates the temporal systems added in
version 1.1.0: calendar months, valid ISO dates, fiscal year/quarter, academic
year/indexed term, extended observation stages, cycle/visit,
year/quarter/month, and signed relative time. It includes normalized-key
collision and incomparable-system controls and protected metadata.

```stata
use "varorder_example_data.dta", clear
varorder
```

The validated example-data preview is a bounded summary:

```text
varorder preview summary

Examined: 146 variables
Confirmed temporal structures: 29
Variables to be reordered: 131
Maximum displacement: 89 columns

Issues requiring review:
  Gap warnings but ordering allowed (2): mobility, vigor
  Related/unverified — no action (6): eng, exercise, lab, mood, promotion_status, reading
  Ambiguous/conflicting — no action (7): focus, memory, mirage, pain, prism_check, score, survey

All eligible structures will be included in the proposed ordering. Structures marked as no action will remain unchanged.


Press Enter to apply the proposed ordering.
```

Pressing Enter in an interactive Stata session applies the frozen plan once and
prints only:

```text
Variable order updated.
```

No variable-by-variable movement listing is printed. In noninteractive batch
execution, the absence of genuine keyboard confirmation declines safely.

## Core behavior

- Evidence may come from variable names, variable labels, variable notes, and
  attached value-label metadata. Value labels provide value-domain/construct
  evidence; their category text is not treated as a variable's measurement
  occasion. Silence is not treated as conflict.
- Supported temporal structures include indexed time/wave/visit forms,
  conservative semantic sequences, repeated calendar years when context is
  temporal, and supported hierarchies such as year > quarter, grade > term, and
  day > within-day period.
- Version 1.1.0 adds explicitly marked calendar months, valid ISO dates,
  fiscal year/quarter, academic year/indexed term, the extended sequence
  screening < baseline < during treatment < discharge < follow-up,
  cycle > visit, year > quarter > month, and signed relative hour/day/week.
- Case, separator, compact-form, and temporal-index zero-padding differences
  (for example, T03 versus T3) are normalized
  internally for inference. Original names, labels, notes, and attached value
  labels are preserved.
- Indexed gaps are reported but do not suppress an otherwise unambiguous family;
  observed pairs such as T1/T3, T1/T4, and T2/T4 remain orderable.
- Bare numeric suffixes and bare q1/q2/q3 are not assumed to be temporal without
  supporting semantics.
- Normalized-key collisions, material metadata conflicts, and ambiguous
  hierarchy are reported and left unchanged.
- Only physical variable order may change. Values, observations, storage types,
  formats, labels, notes, characteristics, sort state, and tsset/xtset state are
  protected.
- Undo is single-level and refuses incompatible dataset states safely.

## Returned results

After `varorder`, machine-readable results include `r(changed)`, `r(k)`, family
state counts, `r(n_moved)`, `r(max_displacement)`, and the complete
`r(oldorder)` and `r(neworder)` lists. See `help varorder` for the exact list.

## Validation and reproducibility

`varorder` requires Stata 16 or later. Version 1.1.0 was developed and validated
with:

```text
C:\Program Files\StataNow19\StataMP-64.exe
StataNow/MP 19.5
```

The highest integrated width actually executed was 5,000 variables. No claim is
made for end-to-end performance at 120,000 variables. Run
`varorder_example.do` for the supplied example workflow and
`varorder_test.do` for the compact public acceptance checks. The production ado
does not read either file during inference.

## Contribution boundary

The defensible contribution is metadata-aware, ambiguity-aware automatic
detection and safe temporal reorganization of variable families in wide-format
Stata datasets. The project does not claim novelty for Stata's native `order`,
numeric-aware sorting alone, label matching alone, undo alone, or constructing a
permutation before applying it.

## Author

Hao Ma, Ph.D.  
Email: shouhuoxiwang2027@gmail.com  
GitHub: [Louis8102](https://github.com/Louis8102/)

## Citation

Ma, H. (2026). *varorder: Automated semantic detection and temporal ordering of
variables in Stata*. Stata module, version 1.1.0.

Citation metadata are also provided in `CITATION.cff`.

## License

`varorder` is free software distributed under the GNU General Public License
version 3 (GPL-3.0). See `LICENSE` for the complete license text.
