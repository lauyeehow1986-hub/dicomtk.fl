# dicomtk.fl: Federated Learning, Trusted Third-Party Custody & Differential Privacy

<!-- badges: start -->
[![R-universe](https://lauyeehow1986-hub.r-universe.dev/badges/:name)](https://lauyeehow1986-hub.r-universe.dev)
<!-- badges: end -->

`dicomtk.fl` (`0.1.0`) is the federated learning and trusted third-party (`TTP`) custody satellite package for [`dicomtk`](https://lauyeehow1986-hub.github.io/dicomtk/). It enables multi-institutional imaging consortia to link cohorts, compute $(\varepsilon, \delta)$-differentially private federated statistics, and emit site packages for **Flower**, **NVIDIA FLARE**, and **OpenFL** under cryptographic **`site_admin`** outbound governance.

---

## Installation

```r
install.packages(
  "dicomtk.fl",
  repos = c(
    "https://lauyeehow1986-hub.r-universe.dev",
    "https://cloud.r-project.org"
  )
)
```

Or install from GitHub:

```r
remotes::install_github("lauyeehow1986-hub/dicomtk.fl")
```

---

## How to Use `dicomtk.fl`

### 1. Trusted Third-Party (Mainzelliste) & Polymorphic Pseudonymisation (`PEP`)
```r
library(dicomtk.fl)

# Offline deterministic TTP (or set mode = "mainzelliste" with base_url)
ttp <- ttp_mainzelliste_client$new(mode = "offline", ttp_secret = "ttp-secret-key")
sess <- ttp$create_session()
root <- ttp$request_pseudonym(
  sess$session_id,
  list(vorname = "Alice", nachname = "Tan", geburtsdatum = "1985-04-12")
)

# Derive unlinkable project- & site-scoped pseudonyms, and re-key across projects
tok_a <- pep_derive_site_token(root$pid, project_id = "PROJ_A", site_id = "SITE_1", pep_key = "pep-master")
tok_b <- pep_rekey_pseudonym(tok_a, target_project_id = "PROJ_B", target_site_id = "SITE_2", pep_key = "pep-master")
tok_a$pseudonym != tok_b$pseudonym
```

### 2. Hardened Bloom-Filter Privacy-Preserving Record Linkage (`PPRL`)
```r
site_a <- tibble::tibble(
  record_id = c("A1", "A2"),
  given_name = c("Alice", "Benjamin"),
  family_name = c("Tan", "Wong"),
  birth_date = c("1985-04-12", "1972-11-03")
)
site_b <- tibble::tibble(
  record_id = c("B1", "B2"),
  given_name = c("Alyce", "Daniel"),
  family_name = c("Tan", "Koh"),
  birth_date = c("1985-04-12", "1968-02-09")
)

# Balanced constant-weight Bloom filters + Dice similarity matching
pprl_link_cohorts(site_a, site_b, secret_key = "consortium-pprl-key", threshold = 0.78)
```

### 3. $(\varepsilon, \delta)$-Differential Privacy Federated Statistics & Budget Accountant
```r
acc <- dp_budget_accountant$new(max_epsilon = 3.0, max_delta = 1e-5)

set.seed(1)
s1 <- dp_federated_summary(rnorm(150, 60, 8), lower = 0, upper = 120, epsilon = 1.0, delta = 1e-6, accountant = acc, site_id = "SITE_1")
s2 <- dp_federated_summary(rnorm(200, 64, 8), lower = 0, upper = 120, epsilon = 1.0, delta = 1e-6, accountant = acc, site_id = "SITE_2")

dp_aggregate_sites(list(s1, s2))
acc$remaining()
```

### 4. `site_admin` Outbound Approval Gate & Flower / NVFlare / OpenFL Export
```r
gate <- fl_site_approval_gate$new(gate_secret = "site-admin-hmac-secret", k_min = 10L)
manifest <- list(site_id = "SITE_1", project_id = "PROJ_LUNG_FL", n_subjects = 150L, modality = "CT")

# Only 'site_admin' can sign an outbound approval receipt
receipt <- gate$approve_export(
  principal = list(user_id = "admin_1", role = "site_admin"),
  manifest = manifest,
  dp_epsilon = 1.0,
  dp_delta = 1e-6,
  min_cell_count = 150L
)

out_dir <- tempfile("fl_bundle_")
fl_export_site_package(manifest, out_dir, framework = "flower", approval_gate = gate, approval_receipt = receipt)
```

### 5. Documentation
Browse the full reference at https://lauyeehow1986-hub.github.io/dicomtk.fl/.
