#' Cryptographic Site-Admin Outbound Approval Gate
#'
#' @description
#' Enforces that no federated learning site bundle or summary table leaves an
#' institution without an explicit cryptographic sign-off from an authenticated
#' `site_admin` principal, verifying minimum-cell k-anonymity and manifest
#' SHA-256 integrity.
#'
#' @export
fl_site_approval_gate <- R6::R6Class(
  "fl_site_approval_gate",
  public = list(
    #' @field k_min Minimum cell count required for outbound approval.
    k_min = 10L,

    #' @description Initialize an outbound approval gate.
    #' @param gate_secret Secret HMAC-SHA256 signing key held by the site governance enclave.
    #' @param k_min Minimum cell count threshold (default `10L`).
    initialize = function(gate_secret, k_min = 10L) {
      if (!is.character(gate_secret) || length(gate_secret) != 1L || !nzchar(gate_secret)) {
        rlang::abort("`gate_secret` must be a non-empty character scalar.", class = "dicomtk_fl_unauthorized_export_error")
      }
      self$k_min <- as.integer(k_min)
      private$gate_secret <- gate_secret
      private$revoked <- new.env(parent = emptyenv())
    },

    #' @description Compute canonical SHA-256 digest of an outbound manifest.
    #' @param manifest Named list describing the outbound cohort/model manifest.
    #' @return Hexadecimal SHA-256 digest string.
    manifest_digest = function(manifest) {
      if (!is.list(manifest) || length(manifest) == 0L) {
        rlang::abort("`manifest` must be a non-empty list.", class = "dicomtk_fl_unauthorized_export_error")
      }
      canonical <- jsonlite::toJSON(
        manifest[sort(names(manifest))],
        auto_unbox = TRUE,
        digits = NA
      )
      unclass(as.character(openssl::sha256(charToRaw(as.character(canonical)))))
    },

    #' @description Issue a signed `site_admin` approval receipt for an outbound manifest.
    #' @param principal List or RBAC principal containing `user_id` and `role`.
    #' @param manifest Named list describing the outbound cohort/bundle.
    #' @param dp_epsilon Optional declared DP epsilon budget.
    #' @param dp_delta Optional declared DP delta budget.
    #' @param min_cell_count Minimum cell count in the outbound dataset/summary.
    #' @return An object of class `"dicomtk_fl_approval_receipt"`.
    approve_export = function(principal,
                              manifest,
                              dp_epsilon = NULL,
                              dp_delta = 0.0,
                              min_cell_count) {
      role <- if (is.list(principal)) principal$role else NULL
      user_id <- if (is.list(principal)) (principal$user_id %||% principal$sub) else NULL
      if (!identical(role, "site_admin")) {
        rlang::abort(
          sprintf("Outbound FL export requires role 'site_admin' (got '%s').", as.character(role %||% "NULL")),
          class = "dicomtk_fl_unauthorized_export_error"
        )
      }
      if (is.null(user_id) || !nzchar(as.character(user_id))) {
        rlang::abort("`principal$user_id` is required.", class = "dicomtk_fl_unauthorized_export_error")
      }
      if (missing(min_cell_count) || is.null(min_cell_count) || as.integer(min_cell_count) < self$k_min) {
        rlang::abort(
          sprintf("Minimum cell count (%s) is below k_min = %d.", as.character(min_cell_count %||% "NA"), self$k_min),
          class = "dicomtk_fl_small_cell_error"
        )
      }

      digest <- self$manifest_digest(manifest)
      receipt_id <- paste0(
        "RCPT-",
        toupper(substr(as.character(openssl::sha256(openssl::rand_bytes(16))), 1L, 16L))
      )
      issued_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      site_id <- as.character(manifest$site_id %||% "SITE_DEFAULT")
      sig_payload <- paste(receipt_id, site_id, digest, user_id, issued_at, sep = "|")
      signature <- unclass(as.character(
        openssl::sha256(charToRaw(sig_payload), key = charToRaw(private$gate_secret))
      ))

      structure(
        list(
          receipt_id = receipt_id,
          site_id = site_id,
          approved_by = as.character(user_id),
          role = "site_admin",
          issued_at = issued_at,
          manifest_digest = digest,
          min_cell_count = as.integer(min_cell_count),
          dp_epsilon = dp_epsilon,
          dp_delta = dp_delta,
          signature = signature
        ),
        class = "dicomtk_fl_approval_receipt"
      )
    },

    #' @description Verify a `site_admin` approval receipt against an outbound manifest.
    #' @param receipt A `"dicomtk_fl_approval_receipt"` object.
    #' @param manifest Named list matching the approved manifest.
    #' @return `TRUE` if valid; otherwise aborts with `dicomtk_fl_unauthorized_export_error`.
    verify_receipt = function(receipt, manifest) {
      if (!inherits(receipt, "dicomtk_fl_approval_receipt")) {
        rlang::abort("Valid 'dicomtk_fl_approval_receipt' required for outbound export.", class = "dicomtk_fl_unauthorized_export_error")
      }
      if (isTRUE(private$revoked[[receipt$receipt_id]])) {
        rlang::abort("Approval receipt has been revoked.", class = "dicomtk_fl_unauthorized_export_error")
      }
      if (!identical(receipt$role, "site_admin")) {
        rlang::abort("Receipt role is not 'site_admin'.", class = "dicomtk_fl_unauthorized_export_error")
      }
      digest <- self$manifest_digest(manifest)
      if (!identical(receipt$manifest_digest, digest)) {
        rlang::abort("Manifest digest does not match signed approval receipt.", class = "dicomtk_fl_unauthorized_export_error")
      }
      sig_payload <- paste(
        receipt$receipt_id,
        receipt$site_id,
        digest,
        receipt$approved_by,
        receipt$issued_at,
        sep = "|"
      )
      expected_sig <- unclass(as.character(
        openssl::sha256(charToRaw(sig_payload), key = charToRaw(private$gate_secret))
      ))
      if (!identical(receipt$signature, expected_sig)) {
        rlang::abort("Approval receipt HMAC signature is invalid.", class = "dicomtk_fl_unauthorized_export_error")
      }
      TRUE
    },

    #' @description Revoke a previously issued approval receipt.
    #' @param receipt_id Character scalar receipt ID.
    revoke_receipt = function(receipt_id) {
      private$revoked[[as.character(receipt_id)]] <- TRUE
      invisible(self)
    }
  ),
  private = list(
    gate_secret = NULL,
    revoked = NULL
  )
)
