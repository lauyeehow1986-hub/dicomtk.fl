# Phase 8 (`dicomtk.fl 0.1.0`) Implementation Plan

> **For Agent:** Use `executing-plans` and `test-driven-development` skills to implement Tasks 1–7 on **Gemini 4 Hydrogen (Medium)**, then switch to **Gemini 4 Argon (High)** for Task 8.

**Goal:** Build, test, verify (`R CMD check --as-cran`: `0 ERRORs | 0 WARNINGs`), push, and register `dicomtk.fl 0.1.0` (`https://github.com/lauyeehow1986-hub/dicomtk.fl`).

---

### Task 1: Package Scaffold, `DESCRIPTION`, `NAMESPACE`, Audit Ledger & Git Init
- **Files:**
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/DESCRIPTION`
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/LICENSE`
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/.Rbuildignore`
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/R/dicomtk.fl-package.R`
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/tests/testthat.R`
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/tests/testthat/test-package-init.R`
- **Verification:** Initialize git repo, run `roxygen2::roxygenise()` and `testthat::test_file("tests/testthat/test-package-init.R")`.

### Task 2: Trusted Third-Party (TTP) Mainzelliste Client & Polymorphic Encryption & Pseudonymisation (`PEP`)
- **Files:**
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/R/ttp-pep.R`
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/tests/testthat/test-ttp-pep.R`
- **Features:**
  - `ttp_mainzelliste_client` R6 class (`create_session()`, `request_pseudonym()`, `resolve_temp_id()`) with offline deterministic mode and live `httr2` Mainzelliste REST mode.
  - `pep_derive_site_token()` & `pep_rekey_pseudonym()`: Cryptographic HMAC-SHA256 polymorphic transformation binding `(master_pseudonym, project_id, site_id, context_key)` so pseudonyms across projects/sites are provably unlinkable while remaining deterministic within a single authorized `(project_id, site_id)` scope.
- **Verification:** Property tests proving cross-project unlinkability (`PID(p, projA) != PID(p, projB)`), determinism within project, and key-sensitivity.

### Task 3: Privacy-Preserving Record Linkage (PPRL) with Hardened Bloom Filters
- **Files:**
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/R/pprl-bloom.R`
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/tests/testthat/test-pprl-bloom.R`
- **Features:**
  - `pprl_encode_bloom()`: Normalizes patient quasi-identifiers, extracts padded character $q$-grams ($q = 2$), maps each $q$-gram via $k$ keyed HMAC-SHA256 double-hashing indices into an $m$-bit vector, supports randomized response bit-flipping (`flip_prob`) and constant-weight balanced Bloom filter encoding (`balanced = TRUE`, length $2m$ with exact Hamming weight $m$).
  - `pprl_dice_similarity()` & `pprl_link_cohorts()`: Computes pairwise Sørensen–Dice similarity across two site cohorts and returns linked pairs above `threshold` with greedy 1-to-1 assignment.
- **Verification:** Tests for exact matches ($S = 1.0$), typo resilience ($S > 0.80$ for 1-character typo), non-matches ($S < 0.40$), balanced Hamming weight invariant ($\sum B_{\text{bal}} = m$), and multi-site linkage accuracy.

### Task 4: Differential Privacy (DP) Federated Statistics, $k$-Anonymity Suppression & Privacy Budget Accountant
- **Files:**
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/R/dp-federated-stats.R`
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/tests/testthat/test-dp-federated-stats.R`
- **Features:**
  - `dp_budget_accountant` R6 class: Tracks $(\varepsilon, \delta)$ queries with ledger history, remaining budget, and hard stop (`dicomtk_fl_dp_budget_exceeded_error`) when cumulative $\varepsilon > \varepsilon_{\max}$ or $\delta > \delta_{\max}$.
  - `dp_suppress_small_cells()`: Suppresses or rejects counts $< k_{\min}$ (default $k_{\min} = 10$).
  - `dp_laplace_mechanism()`, `dp_gaussian_mechanism()`, `dp_federated_summary()`, and `dp_aggregate_sites()`: Computes $(\varepsilon, \delta)$-DP federated counts, bounded means (with explicit clipping $[L, U]$ so global sensitivity $\Delta = (U - L)/N$), variances, and histograms across sites.
- **Verification:** Tests verifying sensitivity calculation, budget exhaustion hard-stop, $k$-anonymity small-cell suppression, and multi-site federated aggregation accuracy.

### Task 5: Federated Learning Site Package Exporters (Flower, NVFlare, OpenFL) & `site_admin` Outbound Approval Gate
- **Files:**
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/R/site-approval.R`
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/R/fl-site-export.R`
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/tests/testthat/test-fl-site-export.R`
- **Features:**
  - `fl_site_approval_gate` R6 class: Requires `role == "site_admin"`, verifies `min_cell_count >= k_min` and DP budget compliance, computes SHA-256 digest of the outbound manifest, and signs an immutable `dicomtk_fl_approval_receipt`.
  - `fl_export_site_package()`: Generates framework-native site bundles for `"flower"`, `"nvflare"`, and `"openfl"` only when a valid, unrevoked `dicomtk_fl_approval_receipt` matching the manifest digest is supplied.
- **Verification:** Property tests proving all non-`site_admin` roles (`pi`, `ml_engineer`, `clinician_annotator`, `honest_broker`, `auditor`) and tampered manifests are rejected with `dicomtk_fl_unauthorized_export_error`.

### Task 6: Vignette (`vignettes/federated_learning_and_ttp.Rmd`), `NEWS.md`, `_pkgdown.yml` & `dicomtk-lab` Integration
- **Files:**
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/vignettes/federated_learning_and_ttp.Rmd`
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/NEWS.md`
  - Create: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.fl/_pkgdown.yml`
- **Verification:** Build vignette and verify all examples execute cleanly.

### Task 7: Full `R CMD check --as-cran --no-manual` Verification (`0 ERRORs | 0 WARNINGs`)
- **Verification:** Run `rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"))` on `dicomtk.fl 0.1.0` and resolve any NOTEs/WARNINGs.

### Task 8: Final Argon (High) Cryptographic PEP, DP Accountant & Site-Approval Audit, GitHub Push & R-Universe Registration
- **Model:** **Gemini 4 Argon (High)**
- **Verification:** Audit cryptographic domain separation in `pep_rekey_pseudonym()`, sensitivity clipping in `dp_federated_summary()`, and manifest digest binding in `fl_export_site_package()`; install `dicomtk.fl 0.1.0` locally; create & push to `https://github.com/lauyeehow1986-hub/dicomtk.fl`; register `dicomtk.fl` in `lauyeehow1986-hub.r-universe.dev/packages.json` and push.
