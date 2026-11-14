test_that("pprl_encode_bloom and pprl_dice_similarity handle exact, typo, and non-match records", {
  key <- "pprl-consortium-hmac-key-2026"
  rec1 <- list(given_name = "Alice", family_name = "Tan", birth_date = "1985-04-12", sex = "F")
  rec1_typo <- list(given_name = "Alyce", family_name = "Tan", birth_date = "1985-04-12", sex = "F")
  rec2 <- list(given_name = "Benjamin", family_name = "Wong", birth_date = "1972-11-03", sex = "M")

  bf1 <- pprl_encode_bloom(rec1, secret_key = key, balanced = FALSE)
  bf1_typo <- pprl_encode_bloom(rec1_typo, secret_key = key, balanced = FALSE)
  bf2 <- pprl_encode_bloom(rec2, secret_key = key, balanced = FALSE)

  expect_s3_class(bf1, "dicomtk_fl_bloom")
  expect_equal(pprl_dice_similarity(bf1, bf1), 1.0)
  expect_gt(pprl_dice_similarity(bf1, bf1_typo), 0.75)
  expect_lt(pprl_dice_similarity(bf1, bf2), 0.40)
})

test_that("balanced Bloom filter maintains exact Hamming weight m", {
  key <- "pprl-consortium-hmac-key-2026"
  rec <- list(given_name = "Marcus", family_name = "Lim", birth_date = "1990-01-15")
  bf_bal <- pprl_encode_bloom(rec, secret_key = key, m = 512L, balanced = TRUE)

  expect_equal(length(bf_bal$bits), 1024L)
  expect_equal(sum(bf_bal$bits), 512L)
})

test_that("randomized response flip_prob is validated and perturbs bits", {
  key <- "pprl-consortium-hmac-key-2026"
  rec <- list(given_name = "Alice", family_name = "Tan", birth_date = "1985-04-12")
  expect_error(pprl_encode_bloom(rec, key, flip_prob = 0.5), class = "dicomtk_fl_pprl_error")

  set.seed(42)
  bf_clean <- pprl_encode_bloom(rec, key, flip_prob = 0.0, balanced = FALSE)
  bf_noisy <- pprl_encode_bloom(rec, key, flip_prob = 0.05, balanced = FALSE)
  expect_lt(pprl_dice_similarity(bf_clean, bf_noisy), 1.0)
  expect_gt(pprl_dice_similarity(bf_clean, bf_noisy), 0.65)
})

test_that("pprl_link_cohorts performs 1-to-1 privacy-preserving cohort linkage", {
  key <- "pprl-consortium-hmac-key-2026"
  site_a <- tibble::tibble(
    record_id = c("A1", "A2", "A3"),
    given_name = c("Alice", "Benjamin", "Clarissa"),
    family_name = c("Tan", "Wong", "Lee"),
    birth_date = c("1985-04-12", "1972-11-03", "1991-08-20")
  )
  site_b <- tibble::tibble(
    record_id = c("B1", "B2", "B3"),
    given_name = c("Benjamin", "Alyce", "Daniel"),
    family_name = c("Wong", "Tan", "Koh"),
    birth_date = c("1972-11-03", "1985-04-12", "1968-02-09")
  )

  links <- pprl_link_cohorts(site_a, site_b, secret_key = key, threshold = 0.78)
  expect_s3_class(links, "tbl_df")
  expect_equal(nrow(links), 2L)
  expect_setequal(links$id_a, c("A1", "A2"))
  expect_setequal(links$id_b, c("B1", "B2"))
})
