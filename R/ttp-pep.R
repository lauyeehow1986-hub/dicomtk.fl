#' Trusted Third-Party (TTP) Mainzelliste Client
#'
#' @description
#' R6 client for interacting with a Mainzelliste Trusted Third-Party (TTP)
#' pseudonymisation service, with an offline deterministic mode for
#' air-gapped testing and simulation.
#'
#' @export
ttp_mainzelliste_client <- R6::R6Class(
  "ttp_mainzelliste_client",
  public = list(
    #' @field base_url Base URL of the Mainzelliste REST service.
    base_url = NULL,
    #' @field mode Either `"offline"` or `"mainzelliste"`.
    mode = "offline",

    #' @description Initialize a Mainzelliste TTP client.
    #' @param base_url Optional Mainzelliste REST URL.
    #' @param api_key Optional API key for Mainzelliste REST calls.
    #' @param mode `"offline"` (default) or `"mainzelliste"`.
    #' @param ttp_secret Secret key used for deterministic offline TTP IDs.
    initialize = function(base_url = NULL,
                          api_key = NULL,
                          mode = c("offline", "mainzelliste"),
                          ttp_secret = "dicomtk-fl-default-ttp-secret") {
      self$mode <- match.arg(mode)
      if (self$mode == "mainzelliste" && (is.null(base_url) || !nzchar(base_url))) {
        rlang::abort(
          "`base_url` is required when `mode = 'mainzelliste'`.",
          class = "dicomtk_fl_ttp_error"
        )
      }
      self$base_url <- base_url
      private$api_key <- api_key
      private$ttp_secret <- ttp_secret
      private$sessions <- new.env(parent = emptyenv())
      private$temp_ids <- new.env(parent = emptyenv())
    },

    #' @description Create a TTP session.
    #' @return A list with `session_id`, `mode`, and `created_at`.
    create_session = function() {
      if (self$mode == "mainzelliste") {
        req <- httr2::request(paste0(sub("/+$", "", self$base_url), "/sessions"))
        if (!is.null(private$api_key) && nzchar(private$api_key)) {
          req <- httr2::req_headers(req, mainzellisteApiKey = private$api_key)
        }
        resp <- httr2::req_perform(httr2::req_method(req, "POST"))
        body <- httr2::resp_body_json(resp)
        sid <- body$sessionId %||% body$id
        return(list(
          session_id = as.character(sid),
          mode = "mainzelliste",
          created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
        ))
      }

      sid <- paste0(
        "sess-",
        substr(
          as.character(openssl::sha256(openssl::rand_bytes(16))),
          1L, 16L
        )
      )
      private$sessions[[sid]] <- TRUE
      list(
        session_id = sid,
        mode = "offline",
        created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      )
    },

    #' @description Request a root TTP pseudonym for patient identifying attributes.
    #' @param session_id Active session identifier from `create_session()`.
    #' @param idat Named list of identifying attributes (e.g., `vorname`, `nachname`, `geburtsdatum`).
    #' @return A list containing `pid`, `temp_id`, and `mode`.
    request_pseudonym = function(session_id, idat) {
      if (!is.character(session_id) || length(session_id) != 1L || !nzchar(session_id)) {
        rlang::abort("Invalid `session_id`.", class = "dicomtk_fl_ttp_error")
      }
      if (!is.list(idat) || length(idat) == 0L) {
        rlang::abort("`idat` must be a non-empty named list.", class = "dicomtk_fl_ttp_error")
      }

      if (self$mode == "mainzelliste") {
        url <- paste0(sub("/+$", "", self$base_url), "/sessions/", session_id, "/tokens")
        req <- httr2::request(url)
        if (!is.null(private$api_key) && nzchar(private$api_key)) {
          req <- httr2::req_headers(req, mainzellisteApiKey = private$api_key)
        }
        req <- httr2::req_body_json(req, list(type = "addPatient", data = idat))
        resp <- httr2::req_perform(req)
        body <- httr2::resp_body_json(resp)
        return(list(
          pid = as.character(body$pid %||% body$id),
          temp_id = as.character(body$tokenId %||% body$tempId %||% ""),
          mode = "mainzelliste"
        ))
      }

      if (!isTRUE(private$sessions[[session_id]])) {
        rlang::abort("Unknown offline TTP `session_id`.", class = "dicomtk_fl_ttp_error")
      }

      nms <- sort(names(idat))
      canonical <- paste(
        vapply(nms, function(nm) {
          val <- tolower(trimws(as.character(idat[[nm]] %||% "")))
          paste0(nm, "=", nchar(val), ":", val)
        }, character(1L)),
        collapse = "|"
      )
      digest_hex <- as.character(
        openssl::sha256(charToRaw(canonical), key = charToRaw(private$ttp_secret))
      )
      pid <- paste0("TTP-", toupper(substr(digest_hex, 1L, 16L)))
      temp_id <- paste0(
        "TMP-",
        toupper(substr(as.character(openssl::sha256(openssl::rand_bytes(16))), 1L, 12L))
      )
      private$temp_ids[[temp_id]] <- pid
      list(pid = pid, temp_id = temp_id, mode = "offline")
    },

    #' @description Resolve an offline temporary token back to its root TTP pseudonym.
    #' @param temp_id Temporary ID returned by `request_pseudonym()`.
    #' @return Character scalar root TTP pseudonym.
    resolve_temp_id = function(temp_id) {
      pid <- private$temp_ids[[temp_id]]
      if (is.null(pid)) {
        rlang::abort("Unknown `temp_id`.", class = "dicomtk_fl_ttp_error")
      }
      pid
    }
  ),
  private = list(
    api_key = NULL,
    ttp_secret = NULL,
    sessions = NULL,
    temp_ids = NULL
  )
)

.pep_validate_nonempty <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x))) {
    rlang::abort(
      paste0("`", arg, "` must be a non-empty character scalar."),
      class = "dicomtk_fl_pep_error"
    )
  }
  x
}

.pep_compute_pseudonym <- function(master_pseudonym,
                                   project_id,
                                   site_id,
                                   pep_key,
                                   context_salt = "v1") {
  payload <- paste0(
    "PEP|",
    nchar(project_id), ":", project_id, "|",
    nchar(site_id), ":", site_id, "|",
    nchar(context_salt), ":", context_salt, "|",
    nchar(master_pseudonym), ":", master_pseudonym
  )
  mac <- as.character(
    openssl::sha256(charToRaw(payload), key = charToRaw(pep_key))
  )
  paste0("PEP-", toupper(substr(mac, 1L, 24L)))
}

.pep_derive_aes_key <- function(pep_key) {
  openssl::sha256(charToRaw(paste0("dicomtk.fl.pep.aes|", pep_key)))
}

#' Derive a Project- and Site-Scoped Polymorphic Pseudonym (PEP)
#'
#' Computes a cryptographically unlinkable project- and site-specific
#' pseudonym from a root TTP `master_pseudonym` using keyed HMAC-SHA256
#' domain separation, and seals an AES-256-GCM envelope so a TTP can re-key
#' the pseudonym for another project without exposing the root identity.
#'
#' @param master_pseudonym Root TTP pseudonym (character scalar).
#' @param project_id Target research project identifier.
#' @param site_id Participating hospital/site identifier.
#' @param pep_key Secret PEP master key.
#' @param context_salt Optional protocol version/context salt (default `"v1"`).
#' @return An object of class `"dicomtk_fl_pep_token"`.
#' @export
#' @examples
#' tok <- pep_derive_site_token("TTP-1234", "PROJ_A", "SITE_1", "secret-key")
#' tok$pseudonym
pep_derive_site_token <- function(master_pseudonym,
                                  project_id,
                                  site_id,
                                  pep_key,
                                  context_salt = "v1") {
  .pep_validate_nonempty(master_pseudonym, "master_pseudonym")
  .pep_validate_nonempty(project_id, "project_id")
  .pep_validate_nonempty(site_id, "site_id")
  .pep_validate_nonempty(pep_key, "pep_key")
  .pep_validate_nonempty(context_salt, "context_salt")

  pseudonym <- .pep_compute_pseudonym(
    master_pseudonym = master_pseudonym,
    project_id = project_id,
    site_id = site_id,
    pep_key = pep_key,
    context_salt = context_salt
  )

  aes_key <- .pep_derive_aes_key(pep_key)
  iv <- openssl::rand_bytes(12L)
  ctx_prefix <- paste0(project_id, "|", site_id, "|", context_salt, "|")
  ct <- openssl::aes_gcm_encrypt(
    data = charToRaw(paste0(ctx_prefix, master_pseudonym)),
    key = aes_key,
    iv = iv
  )

  structure(
    list(
      pseudonym = pseudonym,
      project_id = project_id,
      site_id = site_id,
      context_salt = context_salt,
      envelope = list(
        iv = openssl::base64_encode(iv),
        ciphertext = openssl::base64_encode(as.raw(ct))
      )
    ),
    class = "dicomtk_fl_pep_token"
  )
}

#' Re-Key a PEP Token for a Different Project or Site
#'
#' Unwraps the sealed AES-256-GCM PEP envelope at the TTP and derives a new
#' project- and site-scoped pseudonym without returning the root identity.
#'
#' @param token A `"dicomtk_fl_pep_token"` object.
#' @param target_project_id Destination project identifier.
#' @param target_site_id Destination site identifier.
#' @param pep_key Secret PEP master key.
#' @param context_salt Optional protocol context salt (default `"v1"`).
#' @return A new `"dicomtk_fl_pep_token"` scoped to `target_project_id` and `target_site_id`.
#' @export
pep_rekey_pseudonym <- function(token,
                                target_project_id,
                                target_site_id,
                                pep_key,
                                context_salt = "v1") {
  if (!inherits(token, "dicomtk_fl_pep_token")) {
    rlang::abort("`token` must be a 'dicomtk_fl_pep_token' object.", class = "dicomtk_fl_pep_error")
  }
  .pep_validate_nonempty(target_project_id, "target_project_id")
  .pep_validate_nonempty(target_site_id, "target_site_id")
  .pep_validate_nonempty(pep_key, "pep_key")

  aes_key <- .pep_derive_aes_key(pep_key)
  iv <- openssl::base64_decode(token$envelope$iv)
  ct <- openssl::base64_decode(token$envelope$ciphertext)

  plain_raw <- tryCatch(
    openssl::aes_gcm_decrypt(ct, key = aes_key, iv = iv),
    error = function(e) {
      rlang::abort(
        paste0("PEP envelope decryption failed: ", conditionMessage(e)),
        class = "dicomtk_fl_pep_error"
      )
    }
  )
  plain_str <- rawToChar(plain_raw)
  expected_prefix <- paste0(token$project_id, "|", token$site_id, "|", token$context_salt, "|")
  if (!startsWith(plain_str, expected_prefix)) {
    rlang::abort("PEP envelope context mismatch.", class = "dicomtk_fl_pep_error")
  }
  master_pseudonym <- substr(plain_str, nchar(expected_prefix) + 1L, nchar(plain_str))

  pep_derive_site_token(
    master_pseudonym = master_pseudonym,
    project_id = target_project_id,
    site_id = target_site_id,
    pep_key = pep_key,
    context_salt = context_salt
  )
}
