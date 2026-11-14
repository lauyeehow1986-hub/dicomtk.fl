test_that("fl_site_approval_gate blocks all non-site_admin roles and tampered manifests", {
  gate <- fl_site_approval_gate$new(gate_secret = "site-admin-hmac-secret-2026", k_min = 10L)
  manifest <- list(
    site_id = "SITE_SG_01",
    project_id = "PROJ_LUNG_FL",
    n_subjects = 45L,
    modality = "CT",
    pseudonym_type = "PEP"
  )

  for (bad_role in c("pi", "ml_engineer", "clinician_annotator", "honest_broker", "auditor", "dpo")) {
    expect_error(
      gate$approve_export(
        principal = list(user_id = paste0("u_", bad_role), role = bad_role),
        manifest = manifest,
        min_cell_count = 45L
      ),
      class = "dicomtk_fl_unauthorized_export_error"
    )
  }

  expect_error(
    gate$approve_export(
      principal = list(user_id = "admin1", role = "site_admin"),
      manifest = manifest,
      min_cell_count = 5L
    ),
    class = "dicomtk_fl_small_cell_error"
  )

  receipt <- gate$approve_export(
    principal = list(user_id = "admin1", role = "site_admin"),
    manifest = manifest,
    dp_epsilon = 1.5,
    dp_delta = 1e-6,
    min_cell_count = 45L
  )
  expect_s3_class(receipt, "dicomtk_fl_approval_receipt")
  expect_true(gate$verify_receipt(receipt, manifest))

  tampered_manifest <- manifest
  tampered_manifest$n_subjects <- 46L
  expect_error(
    gate$verify_receipt(receipt, tampered_manifest),
    class = "dicomtk_fl_unauthorized_export_error"
  )
})

test_that("fl_export_site_package generates Flower, NVFlare, and OpenFL bundles only with valid approval", {
  gate <- fl_site_approval_gate$new(gate_secret = "site-admin-hmac-secret-2026", k_min = 10L)
  manifest <- list(
    site_id = "SITE_SG_01",
    project_id = "PROJ_LUNG_FL",
    n_subjects = 120L,
    modality = "CT",
    features = c("glcm_contrast", "shape_volume")
  )
  receipt <- gate$approve_export(
    principal = list(user_id = "admin_sg", role = "site_admin"),
    manifest = manifest,
    dp_epsilon = 2.0,
    dp_delta = 1e-5,
    min_cell_count = 120L
  )

  base_tmp <- withr::local_tempdir()

  flwr_dir <- file.path(base_tmp, "flower")
  res_flwr <- fl_export_site_package(manifest, flwr_dir, framework = "flower", approval_gate = gate, approval_receipt = receipt)
  expect_true(all(file.exists(file.path(flwr_dir, c("pyproject.toml", "client_config.json", "data_manifest.json", "flwr_site_spec.json", "approval_receipt.json")))))
  expect_equal(res_flwr$framework, "flower")

  nv_dir <- file.path(base_tmp, "nvflare")
  res_nv <- fl_export_site_package(manifest, nv_dir, framework = "nvflare", approval_gate = gate, approval_receipt = receipt)
  expect_true(all(file.exists(file.path(nv_dir, c("meta.json", "config_fed_client.json", "config_fed_server.json", "privacy.json", "approval_receipt.json")))))
  expect_equal(res_nv$framework, "nvflare")

  ofl_dir <- file.path(base_tmp, "openfl")
  res_ofl <- fl_export_site_package(manifest, ofl_dir, framework = "openfl", approval_gate = gate, approval_receipt = receipt)
  expect_true(all(file.exists(file.path(ofl_dir, c("plan.json", "cols.json", "data.json", "approval_receipt.json")))))
  expect_equal(res_ofl$framework, "openfl")

  gate$revoke_receipt(receipt$receipt_id)
  expect_error(
    fl_export_site_package(manifest, file.path(base_tmp, "revoked"), framework = "flower", approval_gate = gate, approval_receipt = receipt),
    class = "dicomtk_fl_unauthorized_export_error"
  )
})
