# Federated Learning, Trusted Third-Party Custody & Differential Privacy

## Overview

`dicomtk.fl` enables multi-institutional imaging consortia to
collaborate without centralising patient-level DICOM or clinical
identifiers:

1.  **Trusted Third-Party (TTP) & Polymorphic Pseudonymisation
    (`PEP`)**: `ttp_mainzelliste_client`,
    [`pep_derive_site_token()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pep_derive_site_token.md),
    and
    [`pep_rekey_pseudonym()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pep_rekey_pseudonym.md)
    issue unlinkable project- and site-specific pseudonyms.
2.  **Privacy-Preserving Record Linkage (`PPRL`)**:
    [`pprl_encode_bloom()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pprl_encode_bloom.md),
    [`pprl_dice_similarity()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pprl_dice_similarity.md),
    and
    [`pprl_link_cohorts()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pprl_link_cohorts.md)
    match patients across hospitals using frequency-hardened Bloom
    filters.
3.  **Differential Privacy (`DP`) Federated Statistics**:
    `dp_budget_accountant`,
    [`dp_suppress_small_cells()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_suppress_small_cells.md),
    [`dp_federated_summary()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_federated_summary.md),
    and
    [`dp_aggregate_sites()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_aggregate_sites.md)
    release bounded $`(\varepsilon, \delta)`$-DP cohort summaries while
    enforcing $`k`$-anonymity.
4.  **Governed FL Site Package Exports**: `fl_site_approval_gate` and
    [`fl_export_site_package()`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/fl_export_site_package.md)
    require cryptographic `site_admin` sign-off before emitting Flower,
    NVIDIA FLARE, or OpenFL bundles.

[`library`](https://rdrr.io/r/base/library.html)`(`[`dicomtk.fl`](https://lauyeehow1986-hub.github.io/dicomtk.fl)`)`` `` ``# 1. TTP + Polymorphic Pseudonymisation`` ``ttp`` ``<-`` `[`ttp_mainzelliste_client`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/ttp_mainzelliste_client.md)`$``new``(``mode ``=`` ``"offline"``, ttp_secret ``=`` ``"demo-secret"``)`` ``sess`` ``<-`` ``ttp``$``create_session``(``)`` ``root_id`` ``<-`` ``ttp``$``request_pseudonym``(`` `` ``sess``$``session_id``,`` `` `[`list`](https://rdrr.io/r/base/list.html)`(``vorname ``=`` ``"Alice"``, nachname ``=`` ``"Tan"``, geburtsdatum ``=`` ``"1985-04-12"``)`` ``)`` ``tok_a`` ``<-`` `[`pep_derive_site_token`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pep_derive_site_token.md)`(``root_id``$``pid``, ``"PROJ_A"``, ``"SITE_1"``, ``"pep-key"``)`` ``tok_b`` ``<-`` `[`pep_rekey_pseudonym`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/pep_rekey_pseudonym.md)`(``tok_a``, ``"PROJ_B"``, ``"SITE_2"``, ``"pep-key"``)`` ``tok_a``$``pseudonym`` ``!=`` ``tok_b``$``pseudonym`` ``#> [1] TRUE`` `` ``# 2. DP Federated Summary`` ``acc`` ``<-`` `[`dp_budget_accountant`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_budget_accountant.md)`$``new``(``max_epsilon ``=`` ``3.0``, max_delta ``=`` ``1e-5``)`` `[`set.seed`](https://rdrr.io/r/base/Random.html)`(``1``)`` ``s1`` ``<-`` `[`dp_federated_summary`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_federated_summary.md)`(`[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``120``, ``62``, ``8``)``, lower ``=`` ``0``, upper ``=`` ``120``, accountant ``=`` ``acc``, site_id ``=`` ``"SITE_1"``)`` ``s2`` ``<-`` `[`dp_federated_summary`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_federated_summary.md)`(`[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``150``, ``65``, ``8``)``, lower ``=`` ``0``, upper ``=`` ``120``, accountant ``=`` ``acc``, site_id ``=`` ``"SITE_2"``)`` `[`dp_aggregate_sites`](https://lauyeehow1986-hub.github.io/dicomtk.fl/reference/dp_aggregate_sites.md)`(`[`list`](https://rdrr.io/r/base/list.html)`(``s1``, ``s2``)``)`` ``#> $n_sites`` ``#> [1] 2`` ``#> `` ``#> $site_ids`` ``#> [1] "SITE_1" "SITE_2"`` ``#> `` ``#> $total_count`` ``#> [1] 263.4791`` ``#> `` ``#> $weighted_mean`` ``#> [1] 81.20886`
