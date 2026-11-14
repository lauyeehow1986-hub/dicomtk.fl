test_that("fl_capabilities reports supported frameworks and defaults", {
  caps <- fl_capabilities()
  expect_equal(caps$package, "dicomtk.fl")
  expect_true(all(c("flower", "nvflare", "openfl") %in% caps$fl_frameworks))
  expect_true(all(c("laplace", "gaussian") %in% caps$dp_mechanisms))
  expect_equal(caps$default_k_min, 10L)
})
