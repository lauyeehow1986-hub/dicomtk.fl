#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom R6 R6Class
#' @importFrom rlang %||%
## usethis namespace: end
NULL

#' Package-level federated audit & configuration helper
#'
#' @return A named list describing `dicomtk.fl` capabilities and defaults.
#' @export
#' @examples
#' fl_capabilities()
fl_capabilities <- function() {
  list(
    package = "dicomtk.fl",
    version = as.character(utils::packageVersion("dicomtk.fl")),
    ttp_modes = c("offline", "mainzelliste"),
    pprl_method = "hardened_bloom_filter",
    dp_mechanisms = c("laplace", "gaussian"),
    fl_frameworks = c("flower", "nvflare", "openfl"),
    default_k_min = 10L
  )
}
