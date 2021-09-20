calculate_power <- function(sim_data_fit_file, alpha = 0.05) {
  sim_data_fit <- read_rds(sim_data_fit_file)

  sim_data_fit %>%
    group_by(sim_n_subjects, sim_delta, sim_n_goals) %>%
    summarise(
      n_sim = n(),
      power = mean(p_value < alpha),
      across(starts_with("tscore"),
             .fns = list(mean = mean, sd = sd)),
      .groups = "drop"
    )
}

summarize_effect_size <- function(sim_data_fit_file) {
  sim_data_fit <- read_rds(sim_data_fit_file)

  sim_data_fit %>%
    select(sim, sim_n_subjects, sim_delta, sim_n_goals,
           cohen_d, tscore_control, tscore_treatment) %>%
    nest(cohen_d = c(sim, cohen_d, tscore_control, tscore_treatment)) %>%
    mutate(
      cohen_d_mean = map_dbl(cohen_d, ~mean(.$cohen_d)),
      cohen_d_sd = map_dbl(cohen_d, ~sd(.$cohen_d)),
      cohen_d_median = map_dbl(cohen_d, ~median(.$cohen_d)),
      cohen_d_min = map_dbl(cohen_d, ~min(.$cohen_d)),
      cohen_d_max = map_dbl(cohen_d, ~max(.$cohen_d))
    )
}

#' Compute power difference
#'
#' For each unique combination of simulation parameters (`n_subjects` and effect
#' size `delta`), compute the power difference between different number of goals
#' per subject.
#' Also saves it to a CSV file for the given `save_dir` and `save_filename`.
#'
#' @param ttest_power A data frame of statistical power for different simulation
#'  scenarios, returned by `calculate_power`.
#'
#' @return A data frame with new variables `n_goals1`, `n_goals2`, `power1`,
#'  `power2`, and `power_diff`.
calculate_power_diff <- function(ttest_power, save_dir = NULL,
                                 save_filename = "ttest-power-diff.csv") {
  # Get the unique values of simulated n_goals
  n_goals <- unique(ttest_power$sim_n_goals)

  # Get every combination of n_goals to compare
  ttest_power_diff <-
    crossing(n_goals1 = n_goals, n_goals2 = n_goals) %>%
    # But only compute differences in pairs where n_goals2 > n_goals1
    filter(n_goals2 > n_goals1) %>%
    left_join(
      ttest_power %>%
        select(
          sim_n_subjects, sim_delta,
          n_goals1 = sim_n_goals, power1 = power
        ),
      by = "n_goals1"
    ) %>%
    left_join(
      ttest_power %>%
        select(
          sim_n_subjects, sim_delta,
          n_goals2 = sim_n_goals, power2 = power
        ),
      by = c("sim_n_subjects", "sim_delta", "n_goals2")
    ) %>%
    mutate(power_diff = power2 - power1)

  if (!is.null(save_dir)) {
    write_csv(ttest_power_diff, file.path(save_dir, save_filename))
  }

  return(ttest_power_diff)
}

#' Compute minimum number of goals
#'
#' For each unique combination of simulation parameters (`n_subjects` and effect
#' size `delta`), compute the minimum number of goals required to reach a
#' specified statistical power (default 80%).
#' Also saves it to a CSV file for the given `save_dir` and `save_filename`.
#'
#' @param ttest_power A data frame of statistical power for different simulation
#'  scenarios, returned by `calculate_power`.
#'
#' @return A data frame.
calculate_power_min_goals <- function(
  ttest_power, min_power = 0.8,
  save_dir = NULL, save_filename = "ttest-power-min-goals.csv"
) {
  max_n_goals <- max(ttest_power$sim_n_goals)

  ttest_power_min_goals <- ttest_power %>%
    group_by(sim_n_subjects, sim_delta) %>%
    summarise(
      max_power = max(power),
      min_n_goals = ifelse(max_power < 0.8, str_c(">", max_n_goals),
                           as.character(min(sim_n_goals[power >= min_power]))),
      power = ifelse(max_power < 0.8, NA_real_,
                     min(power[power >= min_power])),
      .groups = "drop"
    ) %>%
    mutate(
      min_n_goals = factor(
        min_n_goals,
        levels = c(seq(1, max_n_goals), str_c(">", max_n_goals)), ordered = TRUE
      )
    )

  if (!is.null(save_dir)) {
    write_csv(ttest_power_min_goals, file.path(save_dir, save_filename))
  }

  return(ttest_power_min_goals)
}
