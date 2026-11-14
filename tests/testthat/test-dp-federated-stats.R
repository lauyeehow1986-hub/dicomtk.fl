test_that("dp_budget_accountant tracks cumulative epsilon/delta and enforces hard stop", {
  acc <- dp_budget_accountant$new(max_epsilon = 2.0, max_delta = 1e-5)
  acc$spend(0.8, 1e-6, "count")
  acc$spend(1.0, 2e-6, "mean")

  rem <- acc$remaining()
  expect_equal(rem$epsilon, 0.2, tolerance = 1e-12)
  expect_equal(rem$delta, 7e-6, tolerance = 1e-15)
  expect_equal(nrow(acc$history()), 2L)

  expect_error(
    acc$spend(0.5, 0, "over_budget"),
    class = "dicomtk_fl_dp_budget_exceeded_error"
  )
})

test_that("dp_suppress_small_cells enforces k-anonymity minimum cell size", {
  counts <- c(A = 25L, B = 4L, C = 0L, D = 12L)
  suppressed <- dp_suppress_small_cells(counts, k_min = 10L)
  expect_equal(unname(suppressed[c("A", "C", "D")]), c(25L, 0L, 12L))
  expect_true(is.na(suppressed["B"]))
  expect_equal(attr(suppressed, "suppressed_count"), 1L)
})

test_that("dp_federated_summary rejects small cohorts and clips sensitivity bounds", {
  acc <- dp_budget_accountant$new(max_epsilon = 3.0, max_delta = 1e-5)
  expect_error(
    dp_federated_summary(c(1, 2, 3), lower = 0, upper = 10, k_min = 10L, accountant = acc),
    class = "dicomtk_fl_small_cell_error"
  )

  set.seed(123)
  x1 <- rnorm(200, mean = 50, sd = 5)
  x2 <- rnorm(250, mean = 54, sd = 5)
  s1 <- dp_federated_summary(x1, lower = 0, upper = 100, epsilon = 1.0, delta = 1e-6, accountant = acc, site_id = "SITE_1")
  s2 <- dp_federated_summary(x2, lower = 0, upper = 100, epsilon = 1.0, delta = 1e-6, accountant = acc, site_id = "SITE_2")

  expect_equal(acc$remaining()$epsilon, 1.0, tolerance = 1e-12)
  agg <- dp_aggregate_sites(list(s1, s2))
  expect_equal(agg$total_count, 450, tolerance = 25)
  expect_equal(agg$weighted_mean, mean(c(x1, x2)), tolerance = 3.0)
})
