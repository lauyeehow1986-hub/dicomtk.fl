# Changelog

## dicomtk.fl 0.1.0

### Initial Release

- **Trusted Third-Party (TTP) & Polymorphic Encryption/Pseudonymisation
  (PEP)**: Added `ttp_mainzelliste_client` (Mainzelliste REST +
  deterministic offline mode),
  [`pep_derive_site_token()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pep_derive_site_token.md),
  and
  [`pep_rekey_pseudonym()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pep_rekey_pseudonym.md)
  for cryptographically unlinkable cross-project/cross-site pseudonyms.
- **Privacy-Preserving Record Linkage (PPRL)**: Added
  [`pprl_encode_bloom()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pprl_encode_bloom.md),
  [`pprl_dice_similarity()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pprl_dice_similarity.md),
  and
  [`pprl_link_cohorts()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pprl_link_cohorts.md)
  with keyed HMAC-SHA256 q-gram double-hashing, randomized response
  bit-flipping, and constant-weight balanced Bloom filter padding.
- **Differential Privacy (DP) Federated Analytics**: Added
  `dp_budget_accountant`,
  [`dp_suppress_small_cells()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_suppress_small_cells.md),
  [`dp_laplace_mechanism()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_laplace_mechanism.md),
  [`dp_gaussian_mechanism()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_gaussian_mechanism.md),
  [`dp_federated_summary()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_federated_summary.md),
  and
  [`dp_aggregate_sites()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_aggregate_sites.md)
  with explicit sensitivity clipping and minimum-cell $`k`$-anonymity
  enforcement.
- **Federated Learning Exporters & Governance Gate**: Added
  `fl_site_approval_gate` (`site_admin`-only HMAC-SHA256 manifest
  signing and revocation) and
  [`fl_export_site_package()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/fl_export_site_package.md)
  for Flower, NVIDIA FLARE, and OpenFL site bundles.
