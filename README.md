# varorder

`varorder` is a Stata module for automatically detecting temporal structure and
reordering eligible variables in wide-format datasets. It uses semantic
information from variable names, variable labels, and variable notes, while
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

Load the example dataset:

```stata
use varorder_example_data.dta, clear
```

Open the help file:

```stata
help varorder
```

Project repository: [github.com/Louis8102/varorder](https://github.com/Louis8102/varorder)

## Practical example

The repository includes `varorder_example_data.dta`, a 5,000-observation,
100-variable development and demonstration dataset with shuffled temporal
families, metadata conflicts, gaps, collisions, Unicode/string fixtures, and
system and extended missing values.

```stata
use "varorder_example_data.dta", clear
varorder
```

The validated example-data preview is a bounded summary:

```text
varorder preview summary
  Examined: 100 variables; candidate structures: 28
  Confirmed: 18; stems: alg, anxiety, bp, depression, health, math (3), memory_time, mobility, read, reading, sales, score (+3 stems omitted)
  Gap warning - ordering allowed (1): mobility: missing indexed position
  Related/unverified - no action (5): [bounded stem and reason summary]
  Ambiguous/conflicting - no action (5): [bounded stem and reason summary]
  Proposed: 18 structures; 98 variables; maximum displacement 90 columns

If you want to proceed, please press Enter.
```

Pressing Enter in an interactive Stata session applies the frozen plan once and
prints a minimal postview:

```text
varorder postview summary
  Updated: yes; examined 100; reorganized 18; moved 98; maximum displacement 90 columns
```

No variable-by-variable movement listing is printed. In noninteractive batch
execution, the absence of genuine keyboard confirmation declines safely.

## Core behavior

- Evidence may come from variable names, variable labels, variable notes, or
  agreement across these sources. Silence is not treated as conflict.
- Supported temporal structures include indexed time/wave/visit forms,
  conservative semantic sequences, repeated calendar years when context is
  temporal, and supported hierarchies such as year > quarter, grade > term, and
  day > within-day period.
- Case, separator, compact-form, and leading-zero differences are normalized
  internally for inference. Original names, labels, and notes are preserved.
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

`varorder` requires Stata 16 or later. Version 1.0.0 was developed and validated
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
variables in Stata*. Stata module, version 1.0.0.

Citation metadata are also provided in `CITATION.cff`.

## License

`varorder` is free software distributed under the GNU General Public License
version 3 (GPL-3.0). See `LICENSE` for the complete license text.
