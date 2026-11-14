# Compute (epsilon, delta)-DP Federated Site Summary

Enforces minimum cohort size `k_min`, clips values to `[lower, upper]`
to bound global sensitivity, and releases noisy count, mean, and
variance.

## Usage

``` r
dp_federated_summary(
  x,
  lower,
  upper,
  epsilon = 1,
  delta = 1e-06,
  k_min = 10L,
  accountant = NULL,
  site_id = "SITE_1"
)
```

## Arguments

- x:

  Numeric vector of local site measurements.

- lower:

  Lower clipping bound.

- upper:

  Upper clipping bound (`upper > lower`).

- epsilon:

  Total epsilon budget for this site summary.

- delta:

  Total delta budget for Gaussian mean/variance release.

- k_min:

  Minimum cohort size required before release (default `10L`).

- accountant:

  Optional `dp_budget_accountant` instance.

- site_id:

  Site identifier string.

## Value

A list of class `"dicomtk_fl_site_summary"`.
