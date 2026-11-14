# Re-Key a PEP Token for a Different Project or Site

Unwraps the sealed AES-256-GCM PEP envelope at the TTP and derives a new
project- and site-scoped pseudonym without returning the root identity.

## Usage

``` r
pep_rekey_pseudonym(
  token,
  target_project_id,
  target_site_id,
  pep_key,
  context_salt = "v1"
)
```

## Arguments

- token:

  A `"dicomtk_fl_pep_token"` object.

- target_project_id:

  Destination project identifier.

- target_site_id:

  Destination site identifier.

- pep_key:

  Secret PEP master key.

- context_salt:

  Optional protocol context salt (default `"v1"`).

## Value

A new `"dicomtk_fl_pep_token"` scoped to `target_project_id` and
`target_site_id`.
