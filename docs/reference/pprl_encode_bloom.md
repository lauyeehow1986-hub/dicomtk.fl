# Encode Quasi-Identifiers into a Hardened PPRL Bloom Filter

Encodes patient quasi-identifiers into character q-grams hashed via
keyed HMAC-SHA256 double-hashing into an `m`-bit Bloom filter, with
optional randomized response bit-flipping (`flip_prob`) and
constant-weight balanced padding (`balanced = TRUE`) to resist frequency
cryptanalysis.

## Usage

``` r
pprl_encode_bloom(
  record,
  secret_key,
  m = 1024L,
  k = 15L,
  q = 2L,
  flip_prob = 0,
  balanced = TRUE
)
```

## Arguments

- record:

  Named list (or 1-row data.frame) of quasi-identifiers.

- secret_key:

  Shared consortium HMAC-SHA256 linkage key.

- m:

  Base Bloom filter length in bits (default `1024L`).

- k:

  Number of hash functions per q-gram (default `15L`).

- q:

  Character q-gram width (default `2L`).

- flip_prob:

  Randomized response bit-flipping probability in `[0, 0.5)` (default
  `0.0`).

- balanced:

  Logical; if `TRUE`, concatenates `bits` and `1L - bits` so Hamming
  weight is strictly `m` (default `TRUE`).

## Value

An object of class `"dicomtk_fl_bloom"`.
