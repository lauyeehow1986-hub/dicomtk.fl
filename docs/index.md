# dicomtk.fl: Federated Learning, Trusted Third-Party Custody & Differential Privacy

`dicomtk.fl` (`0.1.0`) is the federated learning and trusted third-party
(`TTP`) custody satellite package for
[`dicomtk`](https://lauyeehow1986-hub.github.io/dicomtk/). It enables
multi-institutional imaging consortia to link cohorts, compute
$`(\varepsilon, \delta)`$-differentially private federated statistics,
and emit site packages for **Flower**, **NVIDIA FLARE**, and **OpenFL**
under cryptographic **`site_admin`** outbound governance.

------------------------------------------------------------------------

## Installation

[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(`` `` ``"dicomtk.fl"``,`` `` repos ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`` `` ``"https://lauyeehow1986-hub.r-universe.dev"``,`` `` ``"https://cloud.r-project.org"`` `` ``)`` ``)`

Or install from GitHub:

`remotes``::`[`install_github`](https://remotes.r-lib.org/reference/install_github.html)`(``"lauyeehow1986-hub/dicomtk.fl"``)`

------------------------------------------------------------------------

## How to Use `dicomtk.fl`

### 1. Trusted Third-Party (Mainzelliste) & Polymorphic Pseudonymisation (`PEP`)

[`library`](https://rdrr.io/r/base/library.html)`(`[`dicomtk.fl`](https://lauyeehow1986-hub.github.io/dicomtk.fl)`)`` `` ``# Offline deterministic TTP (or set mode = "mainzelliste" with base_url)`` ``ttp`` ``<-`` `[`ttp_mainzelliste_client`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/ttp_mainzelliste_client.md)`$``new``(``mode ``=`` ``"offline"``, ttp_secret ``=`` ``"ttp-secret-key"``)`` ``sess`` ``<-`` ``ttp``$``create_session``(``)`` ``root`` ``<-`` ``ttp``$``request_pseudonym``(`` `` ``sess``$``session_id``,`` `` `[`list`](https://rdrr.io/r/base/list.html)`(``vorname ``=`` ``"Alice"``, nachname ``=`` ``"Tan"``, geburtsdatum ``=`` ``"1985-04-12"``)`` ``)`` `` ``# Derive unlinkable project- & site-scoped pseudonyms, and re-key across projects`` ``tok_a`` ``<-`` `[`pep_derive_site_token`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pep_derive_site_token.md)`(``root``$``pid``, project_id ``=`` ``"PROJ_A"``, site_id ``=`` ``"SITE_1"``, pep_key ``=`` ``"pep-master"``)`` ``tok_b`` ``<-`` `[`pep_rekey_pseudonym`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pep_rekey_pseudonym.md)`(``tok_a``, target_project_id ``=`` ``"PROJ_B"``, target_site_id ``=`` ``"SITE_2"``, pep_key ``=`` ``"pep-master"``)`` ``tok_a``$``pseudonym`` ``!=`` ``tok_b``$``pseudonym`

### 2. Hardened Bloom-Filter Privacy-Preserving Record Linkage (`PPRL`)

`site_a`` ``<-`` ``tibble``::`[`tibble`](https://tibble.tidyverse.org/reference/tibble.html)`(`` `` record_id ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"A1"``, ``"A2"``)``,`` `` given_name ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Alice"``, ``"Benjamin"``)``,`` `` family_name ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Tan"``, ``"Wong"``)``,`` `` birth_date ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"1985-04-12"``, ``"1972-11-03"``)`` ``)`` ``site_b`` ``<-`` ``tibble``::`[`tibble`](https://tibble.tidyverse.org/reference/tibble.html)`(`` `` record_id ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"B1"``, ``"B2"``)``,`` `` given_name ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Alyce"``, ``"Daniel"``)``,`` `` family_name ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Tan"``, ``"Koh"``)``,`` `` birth_date ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"1985-04-12"``, ``"1968-02-09"``)`` ``)`` `` ``# Balanced constant-weight Bloom filters + Dice similarity matching`` `[`pprl_link_cohorts`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pprl_link_cohorts.md)`(``site_a``, ``site_b``, secret_key ``=`` ``"consortium-pprl-key"``, threshold ``=`` ``0.78``)`

### 3. $`(\varepsilon, \delta)`$-Differential Privacy Federated Statistics & Budget Accountant

`acc`` ``<-`` `[`dp_budget_accountant`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_budget_accountant.md)`$``new``(``max_epsilon ``=`` ``3.0``, max_delta ``=`` ``1e-5``)`` `` `[`set.seed`](https://rdrr.io/r/base/Random.html)`(``1``)`` ``s1`` ``<-`` `[`dp_federated_summary`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_federated_summary.md)`(`[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``150``, ``60``, ``8``)``, lower ``=`` ``0``, upper ``=`` ``120``, epsilon ``=`` ``1.0``, delta ``=`` ``1e-6``, accountant ``=`` ``acc``, site_id ``=`` ``"SITE_1"``)`` ``s2`` ``<-`` `[`dp_federated_summary`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_federated_summary.md)`(`[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``200``, ``64``, ``8``)``, lower ``=`` ``0``, upper ``=`` ``120``, epsilon ``=`` ``1.0``, delta ``=`` ``1e-6``, accountant ``=`` ``acc``, site_id ``=`` ``"SITE_2"``)`` `` `[`dp_aggregate_sites`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_aggregate_sites.md)`(`[`list`](https://rdrr.io/r/base/list.html)`(``s1``, ``s2``)``)`` ``acc``$``remaining``(``)`

### 4. `site_admin` Outbound Approval Gate & Flower / NVFlare / OpenFL Export

`gate`` ``<-`` `[`fl_site_approval_gate`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/fl_site_approval_gate.md)`$``new``(``gate_secret ``=`` ``"site-admin-hmac-secret"``, k_min ``=`` ``10L``)`` ``manifest`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(``site_id ``=`` ``"SITE_1"``, project_id ``=`` ``"PROJ_LUNG_FL"``, n_subjects ``=`` ``150L``, modality ``=`` ``"CT"``)`` `` ``# Only 'site_admin' can sign an outbound approval receipt`` ``receipt`` ``<-`` ``gate``$``approve_export``(`` `` principal ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``user_id ``=`` ``"admin_1"``, role ``=`` ``"site_admin"``)``,`` `` manifest ``=`` ``manifest``,`` `` dp_epsilon ``=`` ``1.0``,`` `` dp_delta ``=`` ``1e-6``,`` `` min_cell_count ``=`` ``150L`` ``)`` `` ``out_dir`` ``<-`` `[`tempfile`](https://rdrr.io/r/base/tempfile.html)`(``"fl_bundle_"``)`` `[`fl_export_site_package`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/fl_export_site_package.md)`(``manifest``, ``out_dir``, framework ``=`` ``"flower"``, approval_gate ``=`` ``gate``, approval_receipt ``=`` ``receipt``)`

### 5. Documentation

Browse the full reference at
<https://lauyeehow1986-hub.github.io/dicomtk.fl/>.
