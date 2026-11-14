test_that("ttp_mainzelliste_client creates sessions and deterministic offline pseudonyms", {
  ttp <- ttp_mainzelliste_client$new(mode = "offline", ttp_secret = "ttp-secret-key-01")
  sess <- ttp$create_session()
  expect_true(nzchar(sess$session_id))
  expect_equal(sess$mode, "offline")

  idat <- list(
    vorname = "Alice",
    nachname = "Tan",
    geburtsdatum = "1985-04-12"
  )
  p1 <- ttp$request_pseudonym(sess$session_id, idat)
  p2 <- ttp$request_pseudonym(sess$session_id, idat)
  expect_equal(p1$pid, p2$pid)
  expect_true(grepl("^TTP-", p1$pid))
  expect_equal(ttp$resolve_temp_id(p1$temp_id), p1$pid)
})

test_that("pep_derive_site_token enforces cross-project and cross-site unlinkability", {
  key <- "super-secret-pep-master-key-2026"
  tok_a1 <- pep_derive_site_token("TTP-0001", project_id = "PROJ_A", site_id = "SITE_1", pep_key = key)
  tok_a1_dup <- pep_derive_site_token("TTP-0001", project_id = "PROJ_A", site_id = "SITE_1", pep_key = key)
  tok_b1 <- pep_derive_site_token("TTP-0001", project_id = "PROJ_B", site_id = "SITE_1", pep_key = key)
  tok_a2 <- pep_derive_site_token("TTP-0001", project_id = "PROJ_A", site_id = "SITE_2", pep_key = key)

  expect_s3_class(tok_a1, "dicomtk_fl_pep_token")
  expect_equal(tok_a1$pseudonym, tok_a1_dup$pseudonym)
  expect_false(identical(tok_a1$pseudonym, tok_b1$pseudonym))
  expect_false(identical(tok_a1$pseudonym, tok_a2$pseudonym))
  expect_false(identical(tok_b1$pseudonym, tok_a2$pseudonym))
  expect_false(grepl("TTP-0001", tok_a1$pseudonym, fixed = TRUE))
})

test_that("pep_rekey_pseudonym re-keys across projects without exposing master pseudonym", {
  key <- "super-secret-pep-master-key-2026"
  tok_a1 <- pep_derive_site_token("TTP-0001", project_id = "PROJ_A", site_id = "SITE_1", pep_key = key)
  tok_b2_direct <- pep_derive_site_token("TTP-0001", project_id = "PROJ_B", site_id = "SITE_2", pep_key = key)
  tok_b2_rekey <- pep_rekey_pseudonym(tok_a1, target_project_id = "PROJ_B", target_site_id = "SITE_2", pep_key = key)

  expect_equal(tok_b2_rekey$pseudonym, tok_b2_direct$pseudonym)
  expect_equal(tok_b2_rekey$project_id, "PROJ_B")
  expect_equal(tok_b2_rekey$site_id, "SITE_2")

  expect_error(
    pep_rekey_pseudonym(tok_a1, target_project_id = "PROJ_B", target_site_id = "SITE_2", pep_key = "wrong-key"),
    class = "dicomtk_fl_pep_error"
  )
})

test_that("PEP functions reject empty or invalid inputs", {
  expect_error(pep_derive_site_token("", "P1", "S1", "k"), class = "dicomtk_fl_pep_error")
  expect_error(pep_derive_site_token("TTP-1", "", "S1", "k"), class = "dicomtk_fl_pep_error")
  expect_error(pep_derive_site_token("TTP-1", "P1", "", "k"), class = "dicomtk_fl_pep_error")
  expect_error(pep_derive_site_token("TTP-1", "P1", "S1", ""), class = "dicomtk_fl_pep_error")
})
