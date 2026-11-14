#' Differential Privacy Budget Accountant
#'
#' @description
#' Tracks cumulative `(epsilon, delta)` privacy budget expenditure across
#' federated queries and aborts with `dicomtk_fl_dp_budget_exceeded_error`
#' whenever a query would exceed the configured privacy ceiling.
#'
#' @export
dp_budget_accountant <- R6::R6Class(
  "dp_budget_accountant",
  public = list(
    #' @field max_epsilon Maximum allowed cumulative epsilon.
    max_epsilon = 3.0,
    #' @field max_delta Maximum allowed cumulative delta.
    max_delta = 1e-5,
    #' @field spent_epsilon Cumulative epsilon spent so far.
    spent_epsilon = 0.0,
    #' @field spent_delta Cumulative delta spent so far.
    spent_delta = 0.0,

    #' @description Initialize a privacy budget accountant.
    #' @param max_epsilon Positive numeric ceiling for epsilon.
    #' @param max_delta Non-negative numeric ceiling for delta.
    initialize = function(max_epsilon = 3.0, max_delta = 1e-5) {
      if (!is.numeric(max_epsilon) || length(max_epsilon) != 1L || max_epsilon <= 0) {
        rlang::abort("`max_epsilon` must be > 0.", class = "dicomtk_fl_dp_error")
      }
      if (!is.numeric(max_delta) || length(max_delta) != 1L || max_delta < 0 || max_delta >= 1) {
        rlang::abort("`max_delta` must be in [0, 1).", class = "dicomtk_fl_dp_error")
      }
      self$max_epsilon <- as.numeric(max_epsilon)
      self$max_delta <- as.numeric(max_delta)
      private$entries <- list()
    },

    #' @description Spend `(epsilon, delta)` privacy budget for a named query.
    #' @param epsilon Positive numeric epsilon cost.
    #' @param delta Non-negative numeric delta cost.
    #' @param query_name Descriptive label for the audit ledger.
    #' @return Invisibly returns `self`.
    spend = function(epsilon, delta = 0.0, query_name = "dp_query") {
      if (!is.numeric(epsilon) || length(epsilon) != 1L || epsilon <= 0) {
        rlang::abort("`epsilon` must be > 0.", class = "dicomtk_fl_dp_error")
      }
      if (!is.numeric(delta) || length(delta) != 1L || delta < 0) {
        rlang::abort("`delta` must be >= 0.", class = "dicomtk_fl_dp_error")
      }
      if (self$spent_epsilon + epsilon > self$max_epsilon + 1e-12 ||
          self$spent_delta + delta > self$max_delta + 1e-15) {
        rlang::abort(
          sprintf(
            "DP budget exceeded: requested (eps=%.4g, delta=%.2e), remaining (eps=%.4g, delta=%.2e).",
            epsilon, delta,
            max(0, self$max_epsilon - self$spent_epsilon),
            max(0, self$max_delta - self$spent_delta)
          ),
          class = "dicomtk_fl_dp_budget_exceeded_error"
        )
      }
      self$spent_epsilon <- self$spent_epsilon + as.numeric(epsilon)
      self$spent_delta <- self$spent_delta + as.numeric(delta)
      private$entries[[length(private$entries) + 1L]] <- list(
        timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
        query_name = as.character(query_name),
        epsilon = as.numeric(epsilon),
        delta = as.numeric(delta),
        cumulative_epsilon = self$spent_epsilon,
        cumulative_delta = self$spent_delta
      )
      invisible(self)
    },

    #' @description Return remaining `(epsilon, delta)` privacy budget.
    #' @return Named list with `epsilon` and `delta`.
    remaining = function() {
      list(
        epsilon = max(0, self$max_epsilon - self$spent_epsilon),
        delta = max(0, self$max_delta - self$spent_delta)
      )
    },

    #' @description Return the privacy expenditure ledger as a `tibble`.
    #' @return A `tibble`.
    history = function() {
      if (length(private$entries) == 0L) {
        return(tibble::tibble(
          timestamp = character(0L),
          query_name = character(0L),
          epsilon = numeric(0L),
          delta = numeric(0L),
          cumulative_epsilon = numeric(0L),
          cumulative_delta = numeric(0L)
        ))
      }
      tibble::tibble(
        timestamp = vapply(private$entries, `[[`, character(1L), "timestamp"),
        query_name = vapply(private$entries, `[[`, character(1L), "query_name"),
        epsilon = vapply(private$entries, `[[`, numeric(1L), "epsilon"),
        delta = vapply(private$entries, `[[`, numeric(1L), "delta"),
        cumulative_epsilon = vapply(private$entries, `[[`, numeric(1L), "cumulative_epsilon"),
        cumulative_delta = vapply(private$entries, `[[`, numeric(1L), "cumulative_delta")
      )
    }
  ),
  private = list(
    entries = NULL
  )
)

#' Suppress Small Contingency Cells for k-Anonymity
#'
#' @param counts Numeric or integer vector of cell counts.
#' @param k_min Minimum non-zero cell count allowed without suppression (default `10L`).
#' @return Integer vector with `0 < count < k_min` replaced by `NA_integer_`.
#' @export
dp_suppress_small_cells <- function(counts, k_min = 10L) {
  k_min <- as.integer(k_min)
  if (is.na(k_min) || k_min < 1L) {
    rlang::abort("`k_min` must be >= 1.", class = "dicomtk_fl_dp_error")
  }
  out <- as.integer(counts)
  names(out) <- names(counts)
  small_idx <- !is.na(out) & out > 0L & out < k_min
  out[small_idx] <- NA_integer_
  attr(out, "suppressed_count") <- sum(small_idx)
  out
}

#' Laplace Differential Privacy Mechanism
#'
#' @param value Numeric scalar or vector true statistic.
#' @param sensitivity L1 global sensitivity of `value`.
#' @param epsilon Positive privacy parameter.
#' @param accountant Optional `dp_budget_accountant` instance.
#' @param query_name Audit label for `accountant`.
#' @return Perturbed numeric vector.
#' @export
dp_laplace_mechanism <- function(value,
                                 sensitivity,
                                 epsilon,
                                 accountant = NULL,
                                 query_name = "laplace_query") {
  if (!is.numeric(sensitivity) || sensitivity < 0) {
    rlang::abort("`sensitivity` must be >= 0.", class = "dicomtk_fl_dp_error")
  }
  if (!is.numeric(epsilon) || epsilon <= 0) {
    rlang::abort("`epsilon` must be > 0.", class = "dicomtk_fl_dp_error")
  }
  if (!is.null(accountant)) {
    accountant$spend(epsilon = epsilon, delta = 0.0, query_name = query_name)
  }
  b <- sensitivity / epsilon
  u <- stats::runif(length(value), min = -0.499999999, max = 0.499999999)
  noise <- -b * sign(u) * log(1 - 2 * abs(u))
  as.numeric(value) + noise
}

#' Gaussian (epsilon, delta)-Differential Privacy Mechanism
#'
#' @param value Numeric scalar or vector true statistic.
#' @param sensitivity L2 global sensitivity of `value`.
#' @param epsilon Positive privacy parameter.
#' @param delta Failure probability in `(0, 1)`.
#' @param accountant Optional `dp_budget_accountant` instance.
#' @param query_name Audit label for `accountant`.
#' @return Perturbed numeric vector.
#' @export
dp_gaussian_mechanism <- function(value,
                                  sensitivity,
                                  epsilon,
                                  delta,
                                  accountant = NULL,
                                  query_name = "gaussian_query") {
  if (!is.numeric(sensitivity) || sensitivity < 0) {
    rlang::abort("`sensitivity` must be >= 0.", class = "dicomtk_fl_dp_error")
  }
  if (!is.numeric(epsilon) || epsilon <= 0 || !is.numeric(delta) || delta <= 0 || delta >= 1) {
    rlang::abort("`epsilon` must be > 0 and `delta` in (0, 1).", class = "dicomtk_fl_dp_error")
  }
  if (!is.null(accountant)) {
    accountant$spend(epsilon = epsilon, delta = delta, query_name = query_name)
  }
  sigma <- sensitivity * sqrt(2 * log(1.25 / delta)) / epsilon
  as.numeric(value) + stats::rnorm(length(value), mean = 0, sd = sigma)
}

#' Compute (epsilon, delta)-DP Federated Site Summary
#'
#' Enforces minimum cohort size `k_min`, clips values to `[lower, upper]` to
#' bound global sensitivity, and releases noisy count, mean, and variance.
#'
#' @param x Numeric vector of local site measurements.
#' @param lower Lower clipping bound.
#' @param upper Upper clipping bound (`upper > lower`).
#' @param epsilon Total epsilon budget for this site summary.
#' @param delta Total delta budget for Gaussian mean/variance release.
#' @param k_min Minimum cohort size required before release (default `10L`).
#' @param accountant Optional `dp_budget_accountant` instance.
#' @param site_id Site identifier string.
#' @return A list of class `"dicomtk_fl_site_summary"`.
#' @export
dp_federated_summary <- function(x,
                                 lower,
                                 upper,
                                 epsilon = 1.0,
                                 delta = 1e-6,
                                 k_min = 10L,
                                 accountant = NULL,
                                 site_id = "SITE_1") {
  x <- as.numeric(x[!is.na(x)])
  n <- length(x)
  if (n < as.integer(k_min)) {
    rlang::abort(
      sprintf("Site '%s' cohort size %d is below k_min = %d.", site_id, n, as.integer(k_min)),
      class = "dicomtk_fl_small_cell_error"
    )
  }
  if (!is.numeric(lower) || !is.numeric(upper) || upper <= lower) {
    rlang::abort("`upper` must be strictly greater than `lower`.", class = "dicomtk_fl_dp_error")
  }

  x_clip <- pmin(pmax(x, lower), upper)
  eps_count <- 0.3 * epsilon
  eps_mean <- 0.4 * epsilon
  eps_var <- 0.3 * epsilon
  delta_half <- delta / 2.0

  noisy_n <- max(
    as.numeric(k_min),
    dp_laplace_mechanism(
      value = n,
      sensitivity = 1.0,
      epsilon = eps_count,
      accountant = accountant,
      query_name = paste0(site_id, ":count")
    )
  )
  noisy_mean <- dp_gaussian_mechanism(
    value = mean(x_clip),
    sensitivity = (upper - lower) / n,
    epsilon = eps_mean,
    delta = delta_half,
    accountant = accountant,
    query_name = paste0(site_id, ":mean")
  )
  noisy_var <- max(
    0.0,
    dp_gaussian_mechanism(
      value = stats::var(x_clip),
      sensitivity = ((upper - lower)^2) / n,
      epsilon = eps_var,
      delta = delta_half,
      accountant = accountant,
      query_name = paste0(site_id, ":var")
    )
  )

  structure(
    list(
      site_id = site_id,
      noisy_count = noisy_n,
      noisy_mean = noisy_mean,
      noisy_var = noisy_var,
      epsilon = epsilon,
      delta = delta,
      k_min = as.integer(k_min)
    ),
    class = "dicomtk_fl_site_summary"
  )
}

#' Aggregate Differentially Private Site Summaries Across a Federation
#'
#' @param site_summaries List of `"dicomtk_fl_site_summary"` objects.
#' @return A list with `n_sites`, `total_count`, `weighted_mean`, and `site_ids`.
#' @export
dp_aggregate_sites <- function(site_summaries) {
  if (!is.list(site_summaries) || length(site_summaries) == 0L) {
    rlang::abort("`site_summaries` must be a non-empty list.", class = "dicomtk_fl_dp_error")
  }
  ok <- all(vapply(site_summaries, inherits, logical(1L), "dicomtk_fl_site_summary"))
  if (!ok) {
    rlang::abort("All elements must be 'dicomtk_fl_site_summary' objects.", class = "dicomtk_fl_dp_error")
  }
  counts <- vapply(site_summaries, `[[`, numeric(1L), "noisy_count")
  means <- vapply(site_summaries, `[[`, numeric(1L), "noisy_mean")
  total_n <- sum(counts)
  w_mean <- if (total_n > 0) sum(counts * means) / total_n else NA_real_

  list(
    n_sites = length(site_summaries),
    site_ids = vapply(site_summaries, `[[`, character(1L), "site_id"),
    total_count = total_n,
    weighted_mean = w_mean
  )
}
