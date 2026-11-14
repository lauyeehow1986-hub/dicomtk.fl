# dicomtk.fl 0.1.0

## Initial Release
- **Trusted Third-Party (TTP) & Polymorphic Encryption/Pseudonymisation (PEP)**:
  Added `ttp_mainzelliste_client` (Mainzelliste REST + deterministic offline mode),
  `pep_derive_site_token()`, and `pep_rekey_pseudonym()` for cryptographically
  unlinkable cross-project/cross-site pseudonyms.
- **Privacy-Preserving Record Linkage (PPRL)**:
  Added `pprl_encode_bloom()`, `pprl_dice_similarity()`, and `pprl_link_cohorts()`
  with keyed HMAC-SHA256 q-gram double-hashing, randomized response bit-flipping,
  and constant-weight balanced Bloom filter padding.
- **Differential Privacy (DP) Federated Analytics**:
  Added `dp_budget_accountant`, `dp_suppress_small_cells()`,
  `dp_laplace_mechanism()`, `dp_gaussian_mechanism()`, `dp_federated_summary()`,
  and `dp_aggregate_sites()` with explicit sensitivity clipping and minimum-cell
  $k$-anonymity enforcement.
- **Federated Learning Exporters & Governance Gate**:
  Added `fl_site_approval_gate` (`site_admin`-only HMAC-SHA256 manifest signing
  and revocation) and `fl_export_site_package()` for Flower, NVIDIA FLARE, and
  OpenFL site bundles.
