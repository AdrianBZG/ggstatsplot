#' @title Making text subtitle for the correlation test.
#' @name subtitle_ggscatterstats
#' @author Indrajeet Patil
#'
#' @param type Type of association between paired samples required
#'   ("`"parametric"`: Pearson's product moment correlation coefficient" or
#'   "`"nonparametric"`: Spearman's rho" or "`"robust"`: percentage bend
#'   correlation coefficient" or "`"bayes"`: Bayes Factor for Pearson's *r*").
#'   Corresponding abbreviations are also accepted: `"p"` (for
#'   parametric/pearson's), `"np"` (nonparametric/spearman), `"r"` (robust),
#'   `"bf"` (for bayes factor), resp.
#' @param messages Decides whether messages references, notes, and warnings are
#'   to be displayed (Default: `TRUE`).
#' @inheritParams robcor_ci
#' @inheritParams cor_test_ci
#' @inheritParams bf_corr_test
#' @inheritParams subtitle_t_parametric
#'
#' @importFrom dplyr select
#' @importFrom rlang !! enquo
#' @importFrom stats cor.test
#'
#' @examples
#'
#' # without changing defaults
#' subtitle_ggscatterstats(
#'   data = ggplot2::midwest,
#'   x = area,
#'   y = percblack
#' )
#'
#' # changing defaults
#' subtitle_ggscatterstats(
#'   data = ggplot2::midwest,
#'   x = area,
#'   y = percblack,
#'   nboot = 25,
#'   beta = 0.2,
#'   type = "r",
#'   k = 1
#' )
#' @export

# function body
subtitle_ggscatterstats <- function(data,
                                    x,
                                    y,
                                    nboot = 100,
                                    beta = 0.1,
                                    type = "pearson",
                                    bf.prior = 0.707,
                                    conf.level = 0.95,
                                    conf.type = "norm",
                                    messages = TRUE,
                                    k = 2) {

  #------------------------ dataframe -------------------------------------

  # if dataframe is provided
  data <-
    dplyr::select(
      .data = data,
      x = !!rlang::enquo(x),
      y = !!rlang::enquo(y)
    ) %>%
    stats::na.omit(.) %>%
    tibble::as_tibble(x = .)

  # the total sample size for analysis
  sample_size <- nrow(x = data)

  # standardize the type of statistics
  stats.type <- stats_type_switch(stats.type = type)

  # Pearson's r (will also be used for Bayes tests)
  stats_df <-
    broom::tidy(stats::cor.test(
      formula = ~ x + y,
      data = data,
      method = "pearson",
      alternative = "two.sided",
      exact = FALSE,
      conf.level = conf.level,
      na.action = na.omit
    ))

  #------------------------ Pearson's r -------------------------------------

  if (stats.type == "parametric") {

    # preparing subtitle
    subtitle <- subtitle_template(
      no.parameters = 1L,
      stat.title = NULL,
      statistic.text = quote(italic("t")),
      statistic = stats_df$statistic[[1]],
      parameter = stats_df$parameter[[1]],
      p.value = stats_df$p.value[[1]],
      effsize.text = quote(italic("r")["Pearson"]),
      effsize.estimate = stats_df$estimate,
      effsize.LL = stats_df$conf.low[[1]],
      effsize.UL = stats_df$conf.high[[1]],
      n = sample_size,
      conf.level = conf.level,
      k = k,
      k.parameter = 0L
    )

    #--------------------- Spearnman's rho ---------------------------------
  } else if (stats.type == "nonparametric") {

    # note that stats::cor.test doesn't give degress of freedom; it's
    # calculated as df = (no. of pairs - 2)
    stats_df <-
      broom::tidy(stats::cor.test(
        formula = ~ x + y,
        data = data,
        method = "spearman",
        alternative = "two.sided",
        exact = FALSE,
        na.action = na.omit
      ))

    # getting confidence interval for rho using broom bootstrap
    effsize_df <-
      cor_test_ci(
        data = data,
        x = x,
        y = y,
        nboot = nboot,
        conf.level = conf.level,
        conf.type = conf.type
      )

    # message about effect size measure
    if (isTRUE(messages)) {
      effsize_ci_message(nboot = nboot, conf.level = conf.level)
    }

    # preparing subtitle
    subtitle <- subtitle_template(
      no.parameters = 0L,
      stat.title = NULL,
      statistic.text = quote("log"["e"](italic("S"))),
      statistic = log(stats_df$statistic[[1]]),
      parameter = NULL,
      p.value = stats_df$p.value[[1]],
      effsize.text = quote(italic(rho)["Spearman"]),
      effsize.estimate = stats_df$estimate,
      effsize.LL = effsize_df$conf.low[[1]],
      effsize.UL = effsize_df$conf.high[[1]],
      n = sample_size,
      conf.level = conf.level,
      k = k,
      k.parameter = 0L
    )

    #---------------------- robust percentage bend --------------------------
  } else if (stats.type == "robust") {
    # running robust correlation
    stats_df <-
      robcor_ci(
        data = data,
        x = x,
        y = y,
        beta = beta,
        nboot = nboot,
        conf.level = conf.level,
        conf.type = conf.type
      )

    # preparing subtitle
    subtitle <- subtitle_template(
      no.parameters = 1L,
      stat.title = NULL,
      statistic.text = quote(italic("t")),
      statistic = stats_df$statistic[[1]],
      parameter = (sample_size - 2L),
      p.value = stats_df$p.value[[1]],
      effsize.text = quote(italic(rho)["pb"]),
      effsize.estimate = stats_df$estimate,
      effsize.LL = stats_df$conf.low[[1]],
      effsize.UL = stats_df$conf.high[[1]],
      n = sample_size,
      conf.level = conf.level,
      k = k,
      k.parameter = 0L
    )

    # message about effect size measure
    if (isTRUE(messages)) {
      effsize_ci_message(nboot = nboot, conf.level = conf.level)
    }
    #---------------------- bayes factor -----------------------------------
  } else if (stats.type == "bayes") {

    # bayes factor results
    bf_results <-
      bf_corr_test(
        data = data,
        x = x,
        y = y,
        bf.prior = bf.prior,
        caption = NULL,
        output = "results"
      )

    # preparing the subtitle
    subtitle <-
      base::substitute(
        expr =
          paste(
            italic("r")["Pearson"],
            "(",
            df,
            ")",
            " = ",
            estimate,
            ", log"["e"],
            "(BF"["10"],
            ") = ",
            bf,
            ", ",
            italic("r")["Cauchy"],
            " = ",
            bf_prior,
            ", ",
            italic("n"),
            " = ",
            n
          ),
        env = base::list(
          df = stats_df$parameter[[1]],
          estimate = specify_decimal_p(x = stats_df$estimate[[1]], k = k),
          bf = specify_decimal_p(x = bf_results$log_e_bf10[[1]], k = k),
          bf_prior = specify_decimal_p(x = bf_results$bf.prior[[1]], k = k),
          n = sample_size
        )
      )
  }

  # return the subtitle
  return(subtitle)
}
