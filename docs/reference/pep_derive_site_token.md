# Derive a Project- and Site-Scoped Polymorphic Pseudonym (PEP)

Computes a cryptographically unlinkable project- and site-specific
pseudonym from a root TTP `master_pseudonym` using keyed HMAC-SHA256
domain separation, and seals an AES-256-GCM envelope so a TTP can re-key
the pseudonym for another project without exposing the root identity.

## Usage

``` r
pep_derive_site_token(
  master_pseudonym,
  project_id,
  site_id,
  pep_key,
  context_salt = "v1"
)
```

## Arguments

- master_pseudonym:

  Root TTP pseudonym (character scalar).

- project_id:

  Target research project identifier.

- site_id:

  Participating hospital/site identifier.

- pep_key:

  Secret PEP master key.

- context_salt:

  Optional protocol version/context salt (default `"v1"`).

## Value

An object of class `"dicomtk_fl_pep_token"`.

## Examples

``` r
tok <- pep_derive_site_token("TTP-1234", "PROJ_A", "SITE_1", "secret-key")
tok$pseudonym
#> [1] "PEP-B53ACA3E447206045B397BE3"
```
