.pprl_normalize <- function(x) {
  x <- tolower(trimws(as.character(x %||% "")))
  gsub("[^a-z0-9]", "", x)
}

.pprl_qgrams <- function(s, q = 2L) {
  if (!nzchar(s)) {
    return(character(0L))
  }
  padded <- paste0("_", s, "_")
  n <- nchar(padded)
  if (n < q) {
    return(padded)
  }
  vapply(seq_len(n - q + 1L), function(i) {
    substr(padded, i, i + q - 1L)
  }, character(1L))
}

.pprl_uint32_from_raw <- function(bytes4) {
  b <- as.numeric(bytes4)
  b[1L] * 16777216 + b[2L] * 65536 + b[3L] * 256 + b[4L]
}

#' Encode Quasi-Identifiers into a Hardened PPRL Bloom Filter
#'
#' Encodes patient quasi-identifiers into character q-grams hashed via
#' keyed HMAC-SHA256 double-hashing into an `m`-bit Bloom filter, with optional
#' randomized response bit-flipping (`flip_prob`) and constant-weight
#' balanced padding (`balanced = TRUE`) to resist frequency cryptanalysis.
#'
#' @param record Named list (or 1-row data.frame) of quasi-identifiers.
#' @param secret_key Shared consortium HMAC-SHA256 linkage key.
#' @param m Base Bloom filter length in bits (default `1024L`).
#' @param k Number of hash functions per q-gram (default `15L`).
#' @param q Character q-gram width (default `2L`).
#' @param flip_prob Randomized response bit-flipping probability in `[0, 0.5)` (default `0.0`).
#' @param balanced Logical; if `TRUE`, concatenates `bits` and `1L - bits` so
#'   Hamming weight is strictly `m` (default `TRUE`).
#' @return An object of class `"dicomtk_fl_bloom"`.
#' @export
pprl_encode_bloom <- function(record,
                              secret_key,
                              m = 1024L,
                              k = 15L,
                              q = 2L,
                              flip_prob = 0.0,
                              balanced = TRUE) {
  if (!is.character(secret_key) || length(secret_key) != 1L || !nzchar(secret_key)) {
    rlang::abort("`secret_key` must be a non-empty character scalar.", class = "dicomtk_fl_pprl_error")
  }
  m <- as.integer(m)
  k <- as.integer(k)
  q <- as.integer(q)
  if (is.na(m) || m < 32L || is.na(k) || k < 1L || is.na(q) || q < 1L) {
    rlang::abort("Invalid Bloom filter parameters `m`, `k`, or `q`.", class = "dicomtk_fl_pprl_error")
  }
  if (!is.numeric(flip_prob) || length(flip_prob) != 1L || flip_prob < 0 || flip_prob >= 0.5) {
    rlang::abort("`flip_prob` must be in [0, 0.5).", class = "dicomtk_fl_pprl_error")
  }

  rec <- as.list(record)
  nms <- sort(names(rec))
  if (length(nms) == 0L) {
    rlang::abort("`record` must be a non-empty named list.", class = "dicomtk_fl_pprl_error")
  }

  bits <- integer(m)
  key_raw <- charToRaw(secret_key)

  for (nm in nms) {
    val <- .pprl_normalize(rec[[nm]])
    qgs <- .pprl_qgrams(val, q = q)
    for (qg in qgs) {
      token <- paste0(nm, ":", qg)
      digest <- openssl::sha256(charToRaw(token), key = key_raw)
      h1 <- .pprl_uint32_from_raw(digest[1:4]) %% m
      h2 <- .pprl_uint32_from_raw(digest[5:8]) %% m
      if (h2 == 0) h2 <- 1
      for (i in seq_len(k)) {
        pos <- as.integer(((h1 + (i - 1) * h2) %% m) + 1)
        bits[pos] <- 1L
      }
    }
  }

  if (flip_prob > 0) {
    flips <- stats::runif(m) < flip_prob
    bits[flips] <- 1L - bits[flips]
  }

  if (isTRUE(balanced)) {
    bits <- c(bits, 1L - bits)
  }

  structure(
    list(
      bits = bits,
      m = m,
      k = k,
      q = q,
      balanced = isTRUE(balanced),
      flip_prob = flip_prob
    ),
    class = "dicomtk_fl_bloom"
  )
}

#' Compute Sorensen-Dice Similarity Between Two Bloom Filters
#'
#' @param bf1 A `"dicomtk_fl_bloom"` object.
#' @param bf2 A `"dicomtk_fl_bloom"` object of identical length.
#' @return Numeric scalar similarity in `[0, 1]`.
#' @export
pprl_dice_similarity <- function(bf1, bf2) {
  if (!inherits(bf1, "dicomtk_fl_bloom") || !inherits(bf2, "dicomtk_fl_bloom")) {
    rlang::abort("Both inputs must be 'dicomtk_fl_bloom' objects.", class = "dicomtk_fl_pprl_error")
  }
  if (length(bf1$bits) != length(bf2$bits)) {
    rlang::abort("Bloom filter lengths do not match.", class = "dicomtk_fl_pprl_error")
  }
  denom <- sum(bf1$bits) + sum(bf2$bits)
  if (denom == 0L) {
    return(0.0)
  }
  2.0 * sum(bf1$bits & bf2$bits) / denom
}

#' Privacy-Preserving Record Linkage Across Two Site Cohorts
#'
#' @param cohort_a Data frame with `record_id` and quasi-identifier columns.
#' @param cohort_b Data frame with `record_id` and quasi-identifier columns.
#' @param secret_key Shared consortium HMAC-SHA256 linkage key.
#' @param id_col Name of the identifier column (default `"record_id"`).
#' @param threshold Minimum Dice similarity for a match (default `0.85`).
#' @param m Bloom filter base length (default `1024L`).
#' @param k Number of hash functions (default `15L`).
#' @param flip_prob Randomized response bit-flipping probability (default `0.0`).
#' @param balanced Use balanced constant-weight Bloom filters (default `TRUE`).
#' @return A `tibble` with `id_a`, `id_b`, and `dice_similarity`.
#' @export
pprl_link_cohorts <- function(cohort_a,
                              cohort_b,
                              secret_key,
                              id_col = "record_id",
                              threshold = 0.85,
                              m = 1024L,
                              k = 15L,
                              flip_prob = 0.0,
                              balanced = TRUE) {
  if (!id_col %in% names(cohort_a) || !id_col %in% names(cohort_b)) {
    rlang::abort(
      paste0("Both cohorts must contain `", id_col, "`."),
      class = "dicomtk_fl_pprl_error"
    )
  }
  qi_cols <- intersect(setdiff(names(cohort_a), id_col), setdiff(names(cohort_b), id_col))
  if (length(qi_cols) == 0L) {
    rlang::abort("No common quasi-identifier columns between cohorts.", class = "dicomtk_fl_pprl_error")
  }

  enc_a <- lapply(seq_len(nrow(cohort_a)), function(i) {
    pprl_encode_bloom(
      as.list(cohort_a[i, qi_cols, drop = FALSE]),
      secret_key = secret_key, m = m, k = k, flip_prob = flip_prob, balanced = balanced
    )
  })
  enc_b <- lapply(seq_len(nrow(cohort_b)), function(j) {
    pprl_encode_bloom(
      as.list(cohort_b[j, qi_cols, drop = FALSE]),
      secret_key = secret_key, m = m, k = k, flip_prob = flip_prob, balanced = balanced
    )
  })

  candidates <- vector("list", length(enc_a) * length(enc_b))
  idx <- 0L
  for (i in seq_along(enc_a)) {
    for (j in seq_along(enc_b)) {
      sim <- pprl_dice_similarity(enc_a[[i]], enc_b[[j]])
      if (sim >= threshold) {
        idx <- idx + 1L
        candidates[[idx]] <- list(
          id_a = as.character(cohort_a[[id_col]][i]),
          id_b = as.character(cohort_b[[id_col]][j]),
          dice_similarity = sim
        )
      }
    }
  }

  if (idx == 0L) {
    return(tibble::tibble(id_a = character(0L), id_b = character(0L), dice_similarity = numeric(0L)))
  }

  cand_df <- tibble::tibble(
    id_a = vapply(candidates[seq_len(idx)], `[[`, character(1L), "id_a"),
    id_b = vapply(candidates[seq_len(idx)], `[[`, character(1L), "id_b"),
    dice_similarity = vapply(candidates[seq_len(idx)], `[[`, numeric(1L), "dice_similarity")
  )
  cand_df <- cand_df[order(cand_df$dice_similarity, decreasing = TRUE), , drop = FALSE]

  used_a <- character(0L)
  used_b <- character(0L)
  keep <- logical(nrow(cand_df))
  for (r in seq_len(nrow(cand_df))) {
    a <- cand_df$id_a[r]
    b <- cand_df$id_b[r]
    if (!(a %in% used_a) && !(b %in% used_b)) {
      keep[r] <- TRUE
      used_a <- c(used_a, a)
      used_b <- c(used_b, b)
    }
  }
  tibble::as_tibble(cand_df[keep, , drop = FALSE])
}
