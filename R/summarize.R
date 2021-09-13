summarize_power <- function(sim_data_fit_file, alpha = 0.05,
                            save_dir = NULL, save_filename = NULL) {
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
