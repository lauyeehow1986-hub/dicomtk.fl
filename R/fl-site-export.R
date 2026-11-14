#' Export a Governed Federated Learning Site Bundle (Flower, NVFlare, or OpenFL)
#'
#' Validates a signed `site_admin` approval receipt against `cohort_manifest`,
#' then writes a framework-specific site configuration bundle (`"flower"`,
#' `"nvflare"`, or `"openfl"`) to `out_dir`.
#'
#' @param cohort_manifest Named list describing the local site cohort and feature schema.
#' @param out_dir Output directory path where the site bundle is written.
#' @param framework Target FL framework: `"flower"`, `"nvflare"`, or `"openfl"`.
#' @param approval_gate A `fl_site_approval_gate` R6 instance.
#' @param approval_receipt Signed `dicomtk_fl_approval_receipt` issued by `site_admin`.
#' @param dp_config Optional differential privacy hyperparameters (`clip_norm`, `noise_multiplier`).
#' @return Invisibly returns a list summarizing the exported bundle and written files.
#' @export
fl_export_site_package <- function(cohort_manifest,
                                   out_dir,
                                   framework = c("flower", "nvflare", "openfl"),
                                   approval_gate,
                                   approval_receipt,
                                   dp_config = list(clip_norm = 1.0, noise_multiplier = 1.1)) {
  framework <- match.arg(framework)
  if (!inherits(approval_gate, "fl_site_approval_gate")) {
    rlang::abort("`approval_gate` must be a 'fl_site_approval_gate' object.", class = "dicomtk_fl_unauthorized_export_error")
  }
  approval_gate$verify_receipt(approval_receipt, cohort_manifest)

  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  }

  site_id <- as.character(cohort_manifest$site_id %||% approval_receipt$site_id)
  project_id <- as.character(cohort_manifest$project_id %||% "DICOMTK_FL_PROJECT")

  written <- character(0L)
  write_json_file <- function(fname, obj) {
    fpath <- file.path(out_dir, fname)
    writeLines(jsonlite::toJSON(obj, auto_unbox = TRUE, pretty = TRUE), fpath)
    written <<- c(written, fpath)
  }

  if (framework == "flower") {
    pyproject_path <- file.path(out_dir, "pyproject.toml")
    writeLines(
      c(
        "[build-system]",
        "requires = [\"hatchling\"]",
        "build-backend = \"hatchling.build\"",
        "",
        "[project]",
        sprintf("name = \"%s-site-%s\"", tolower(project_id), tolower(site_id)),
        "version = \"0.1.0\"",
        "dependencies = [\"flwr>=1.12.0\", \"opacus>=1.4.0\"]"
      ),
      pyproject_path
    )
    written <- c(written, pyproject_path)

    write_json_file("client_config.json", list(
      site_id = site_id,
      project_id = project_id,
      mtls_enabled = TRUE,
      dp = dp_config
    ))
    write_json_file("data_manifest.json", cohort_manifest)
    write_json_file("flwr_site_spec.json", list(
      supernode = list(partition_id = site_id, tls_ca = "certs/ca.crt"),
      dp_accountant = list(epsilon = approval_receipt$dp_epsilon, delta = approval_receipt$dp_delta)
    ))
  } else if (framework == "nvflare") {
    write_json_file("meta.json", list(
      name = paste0(project_id, "_", site_id),
      resource_spec = list(num_gpus = 0L),
      min_clients = 2L
    ))
    write_json_file("config_fed_client.json", list(
      format_version = 2L,
      site_id = site_id,
      executors = list(list(tasks = list("train", "validate"), path = "dicomtk_fl.nvflare.ClientExecutor")),
      task_result_filters = list(list(
        tasks = list("train"),
        filters = list(list(name = "SVTPrivacy", args = list(fraction = 0.1, epsilon = approval_receipt$dp_epsilon %||% 1.0)))
      ))
    ))
    write_json_file("config_fed_server.json", list(
      format_version = 2L,
      min_clients = 2L,
      num_rounds = 10L
    ))
    write_json_file("privacy.json", list(
      b_policy = "dicomtk_fl_strict",
      clip_norm = dp_config$clip_norm,
      noise_multiplier = dp_config$noise_multiplier,
      min_cell_count = approval_receipt$min_cell_count
    ))
  } else {
    write_json_file("plan.json", list(
      network = list(agg_addr = "aggregator.consortium.local", tls = TRUE),
      aggregator = list(settings = list(rounds_to_train = 10L)),
      collaborator = list(settings = list(site_id = site_id, dp = dp_config))
    ))
    write_json_file("cols.json", list(collaborators = list(site_id)))
    write_json_file("data.json", cohort_manifest)
  }

  write_json_file("approval_receipt.json", unclass(approval_receipt))

  invisible(list(
    framework = framework,
    site_id = site_id,
    out_dir = out_dir,
    files = written,
    receipt_id = approval_receipt$receipt_id
  ))
}
