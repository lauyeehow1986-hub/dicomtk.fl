# Gaussian (epsilon, delta)-Differential Privacy Mechanism

Gaussian (epsilon, delta)-Differential Privacy Mechanism

## Usage

``` r
dp_gaussian_mechanism(
  value,
  sensitivity,
  epsilon,
  delta,
  accountant = NULL,
  query_name = "gaussian_query"
)
```

## Arguments

- value:

  Numeric scalar or vector true statistic.

- sensitivity:

  L2 global sensitivity of `value`.

- epsilon:

  Positive privacy parameter.

- delta:

  Failure probability in `(0, 1)`.

- accountant:

  Optional `dp_budget_accountant` instance.

- query_name:

  Audit label for `accountant`.

## Value

Perturbed numeric vector.
