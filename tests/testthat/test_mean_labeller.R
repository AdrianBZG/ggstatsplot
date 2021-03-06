# context ------------------------------------------------------------
context(desc = "mean_labeller")

# mean labelling works -------------------------------------------------------

testthat::test_that(
  desc = "mean_labeller works",
  code = {
    testthat::skip_on_cran()

    # ----------------------- data without NAs ------------------------------

    # creating a smaller dataframe
    set.seed(123)
    diamonds_short <-
      dplyr::sample_frac(tbl = ggplot2::diamonds, size = 0.05) %>%
      dplyr::filter(.data = ., cut != "Ideal")

    # ggstatsplot output
    set.seed(123)
    mean_dat <-
      ggstatsplot:::mean_labeller(
        data = diamonds_short,
        x = cut,
        y = price,
        mean.ci = TRUE,
        k = 3
      )

    # check that dropped factor level is not retained
    testthat::expect_equal(
      object = length(levels(mean_dat$x)) + 1,
      expected = length(levels(diamonds_short$cut))
    )

    if (utils::packageVersion("skimr") != "2.0") {
      # check mean label for first factor level
      testthat::expect_identical(
        object = mean_dat$label[[1]],
        expected = "3759.200, 95% CI [3160.528, 4357.872]"
      )

      # check mean label for first factor level
      testthat::expect_identical(
        object = mean_dat$label[[4]],
        expected = "4866.200, 95% CI [4527.173, 5205.227]"
      )
    } else {
      # check mean label for first factor level
      testthat::expect_identical(
        object = mean_dat$label[[1]],
        expected = "3759.196, 95% CI [3160.523, 4357.869]"
      )

      # check mean label for first factor level
      testthat::expect_identical(
        object = mean_dat$label[[4]],
        expected = "4866.200, 95% CI [4527.172, 5205.227]"
      )
    }

    # check sample size label for first factor level
    testthat::expect_identical(
      object = mean_dat$n_label[[1]],
      expected = "Fair\n(n = 97)"
    )

    # check sample size label for first factor level
    testthat::expect_identical(
      object = mean_dat$n_label[[4]],
      expected = "Premium\n(n = 686)"
    )

    # ------------------------- data with NAs ------------------------------

    # ggstatsplot output
    set.seed(123)
    mean_dat2 <- ggstatsplot:::mean_labeller(
      data = ggplot2::msleep,
      x = "vore",
      y = "brainwt",
      mean.ci = TRUE,
      k = 3
    )

    # when factor level contains NAs
    testthat::expect_equal(
      object = length(levels(mean_dat2$x)),
      expected = length(levels(as.factor(
        ggplot2::msleep$vore
      )))
    )
  }
)
