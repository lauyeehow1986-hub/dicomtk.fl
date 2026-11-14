# Laplace Differential Privacy Mechanism

Laplace Differential Privacy Mechanism

## Usage

``` r
dp_laplace_mechanism(
  value,
  sensitivity,
  epsilon,
  accountant = NULL,
  query_name = "laplace_query"
)
```

## Arguments

- value:

  Numeric scalar or vector true statistic.

- sensitivity:

  L1 global sensitivity of `value`.

- epsilon:

  Positive privacy parameter.

- accountant:

  Optional `dp_budget_accountant` instance.

- query_name:

  Audit label for `accountant`.

## Value

Perturbed numeric vector.
