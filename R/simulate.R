simulate <- function(
  n_subjects = 100, delta = 0.3, n_goals = 3, n_sim = 1e4,
  save_dir = NULL, save_filename = NULL
) {
  d <- tibble(
    sim = 1:n_sim
  ) %>%
    rowwise() %>%
    mutate(
      sim_n_subjects = n_subjects, sim_n_goals = n_goals, sim_delta = delta,
      data = list(gasr::sim_trial(n_subjects = n_subjects, delta = delta,
                                  n_goals = n_goals))
    ) %>%
    ungroup()

  save_dir_filename <- file.path(save_dir, str_c(save_filename, ".rds"))

  saveRDS(d, save_dir_filename)

  return(save_dir_filename)
}
