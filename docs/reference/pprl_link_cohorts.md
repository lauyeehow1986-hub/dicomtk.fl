# Privacy-Preserving Record Linkage Across Two Site Cohorts

Privacy-Preserving Record Linkage Across Two Site Cohorts

## Usage

``` r
pprl_link_cohorts(
  cohort_a,
  cohort_b,
  secret_key,
  id_col = "record_id",
  threshold = 0.85,
  m = 1024L,
  k = 15L,
  flip_prob = 0,
  balanced = TRUE
)
```

## Arguments

- cohort_a:

  Data frame with `record_id` and quasi-identifier columns.

- cohort_b:

  Data frame with `record_id` and quasi-identifier columns.

- secret_key:

  Shared consortium HMAC-SHA256 linkage key.

- id_col:

  Name of the identifier column (default `"record_id"`).

- threshold:

  Minimum Dice similarity for a match (default `0.85`).

- m:

  Bloom filter base length (default `1024L`).

- k:

  Number of hash functions (default `15L`).

- flip_prob:

  Randomized response bit-flipping probability (default `0.0`).

- balanced:

  Use balanced constant-weight Bloom filters (default `TRUE`).

## Value

A `tibble` with `id_a`, `id_b`, and `dice_similarity`.
