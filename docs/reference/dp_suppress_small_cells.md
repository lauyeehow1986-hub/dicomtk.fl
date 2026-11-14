# Suppress Small Contingency Cells for k-Anonymity

Suppress Small Contingency Cells for k-Anonymity

## Usage

``` r
dp_suppress_small_cells(counts, k_min = 10L)
```

## Arguments

- counts:

  Numeric or integer vector of cell counts.

- k_min:

  Minimum non-zero cell count allowed without suppression (default
  `10L`).

## Value

Integer vector with `0 < count < k_min` replaced by `NA_integer_`.
