# Phase 8 (`dicomtk.fl 0.1.0`): Federated Learning, Trusted Third-Party (TTP) Custody, PPRL/PEP & Differential Privacy Design

**Date:** 2026-11-14  
**Package:** `dicomtk.fl` (`0.1.0`)  
**Repository:** `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl`  
**Dependencies:** `dicomtk (>= 0.6.0)`, `dicomtk.server (>= 1.0.0)`, `R6`, `cli`, `rlang`, `jsonlite`, `openssl`, `httr2`, `tibble`

---

## 1. Architectural Vision & Scope

`dicomtk.fl` completes the 4-package `dicomtk` suite (`dicomtk`, `dicomtk.ai`, `dicomtk.server`, `dicomtk.fl`) by enabling multi-institutional federated imaging research without centralising raw patient data or allowing cross-project re-identification linkage:

1. **Trusted Third-Party (TTP) Connector & Polymorphic Encryption & Pseudonymisation (`R/ttp-pep.R`)**:
   - **`ttp_mainzelliste_client`**: R6 client for external Mainzelliste REST TTP services (`/sessions`, `/sessions/{id}/tokens`, `/patients`) with deterministic offline fallback for air-gapped testing.
   - **Polymorphic Encryption & Pseudonymisation (`pep_rekey_pseudonym()`, `pep_derive_site_token()`)**: Uses double-keyed HMAC-SHA256 blind-index derivation where a Trusted Third-Party master token is cryptographically transformed via a `(project_id, site_id, context_salt)` polymorphism factor so two research projects (`project_A` vs `project_B`) or two sites receive provably unlinkable project-specific pseudonyms (`PID_A != PID_B`) for the same underlying patient without exposing the root identity.
2. **Privacy-Preserving Record Linkage (PPRL) via Hardened Cryptographic Long-term Keys / Bloom Filters (`R/pprl-bloom.R`)**:
   - **`pprl_encode_bloom()`**: Encodes quasi-identifiers (`given_name`, `family_name`, `birth_date`, `sex`, `postal_code`) into character $q$-grams ($q=2$), hashes each $q$-gram with $k$ independent keyed HMAC-SHA256 functions into an $m$-bit Bloom filter (default $m = 1024, k = 15$), and applies **randomized response bit-flipping** ($p_{\text{flip}} \in [0, 0.5)$) + **frequency-hardened balanced padding** (optional $2m$-bit constant-weight balanced encoding) to defeat cryptanalytic frequency attacks.
   - **`pprl_dice_similarity()` & `pprl_link_cohorts()`**: Computes Sørensen–Dice similarity $S = \frac{2 |B_1 \cap B_2|}{|B_1| + |B_2|}$ across site Bloom-filter tables with configurable threshold (e.g. $\tau = 0.85$) and greedy 1-to-1 bipartite matching to deduplicate cross-hospital imaging patients without sharing cleartext PII.
3. **Differential Privacy (DP) Federated Statistics & Privacy Budget Accountant (`R/dp-federated-stats.R`)**:
   - **`dp_budget_accountant`**: R6 privacy ledger tracking cumulative $(\varepsilon, \delta)$ expenditure across queries under Basic Composition and Advanced / Zero-Concentrated DP (zCDP / Gaussian Moments) bounds, automatically rejecting queries that would exceed `max_epsilon` or `max_delta` (`class = "dicomtk_fl_dp_budget_exceeded_error"`).
   - **`dp_suppress_small_cells()`**: Enforces minimum cell count $k$-anonymity ($n < k_{\min}$, default $k_{\min} = 10$) before any noisy release, suppressing or coarsening sparse strata (`class = "dicomtk_fl_small_cell_error"` when whole-cohort $N < k_{\min}$).
   - **`dp_mechanisms`**: Calibrated Laplace ($\Delta_1 / \varepsilon$) and Gaussian ($\Delta_2 \sqrt{2 \ln(1.25/\delta)} / \varepsilon$) noise mechanisms for federated counts, means, variances, histograms, and contingency tables (`dp_federated_summary()`, `dp_aggregate_sites()`).
4. **Federated Learning Site Package Exporters — Flower, NVIDIA FLARE & OpenFL (`R/fl-site-export.R`)**:
   - **`fl_export_site_package()`**: Converts a local `dicomtk` / `dicomtk.ai` cohort + radiomics/DL manifest into ready-to-launch site client bundles for:
     - **Flower (`framework = "flower"`)**: `pyproject.toml`, `client_config.json`, `data_manifest.json`, and `flwr_site_spec.json` with mTLS certificate placeholders and DP clipping parameters (`clip_norm`, `noise_multiplier`).
     - **NVIDIA FLARE (`framework = "nvflare"`)**: `meta.json`, `config_fed_client.json`, `config_fed_server.json`, and `privacy.json` compatible with NVFlare 2.4+ Job API and filter chains (`SVTPrivacy`, `PercentilePrivacy`, `ExcludeVars`).
     - **OpenFL (`framework = "openfl"`)**: `plan.yaml`-compatible JSON/YAML collaborator manifest, `cols.yaml`, and `data.yaml` shard descriptors.
5. **Cryptographic `site_admin` Outbound Approval Gate (`R/site-approval.R`)**:
   - **`fl_site_approval_gate`**: R6 outbound governance gate enforcing that no FL site package or federated summary table can be exported or transmitted until an authenticated `site_admin` (verified via `dicomtk.server` RBAC principal or local HMAC signature) inspects the SHA-256 manifest digest, DP $(\varepsilon, \delta)$ expenditure, and minimum-cell $k$-anonymity attestation, issuing a signed `dicomtk_fl_approval_receipt`.
   - Any attempt to finalize outbound federated export without a valid `site_admin` receipt or by a non-`site_admin` role (`pi`, `clinician_annotator`, `ml_engineer`, `honest_broker`) raises `class = "dicomtk_fl_unauthorized_export_error"`.
