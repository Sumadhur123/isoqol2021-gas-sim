fit_ttest <- function(sim_data_file,
                      save_dir = NULL, save_filename = NULL) {
  sim_data <- read_rds(sim_data_file)

  m <- sim_data %>%
    mutate(
      ttest = map(
        data,
        ~t.test(
          tscore ~ group,
          data = distinct(., subject_id, group, tscore)
        ) %>%
          broom::tidy()
      ),
      cohen_d = map_dbl(
        data,
        ~distinct(., subject_id, group, tscore) %>%
          summarise(
            tscore_treatment = mean(tscore[group == "treatment"]),
            tscore_control = mean(tscore[group == "control"]),
            # Difference in means divided by pooled standard deviation
            cohen_d = (tscore_treatment - tscore_control) / sd(tscore),
            .groups = "drop"
          ) %>%
          pull(cohen_d)
      )
    ) %>%
    select(-data) %>%
    unnest(ttest) %>%
    rename(
      tscore_diff = estimate,
      tscore_diff_conf_low = conf.low, tscore_diff_conf_high = conf.high,
      tscore_control = estimate1, tscore_treatment = estimate2,
      t = statistic, p_value = p.value, df = parameter
    )

  save_dir_filename <- file.path(save_dir,
                                 str_c("ttest_", save_filename, ".rds"))
  saveRDS(m, save_dir_filename)

  return(save_dir_filename)
}

#' Save the combined t-test power data and return the filename
save_ttest_power <- function(ttest_power, save_dir = NULL,
                             save_filename = "ttest-power.csv") {
  save_dir_filename <- file.path(save_dir, save_filename)

  write_csv(ttest_power, save_dir_filename)

  return(save_dir_filename)
}

#' Save the combined effect size data and return the filename
save_effect_size <- function(effect_size, save_dir = NULL,
                             save_filename = "effect-size.csv") {
  save_dir_filename <- file.path(save_dir, save_filename)

  # Drop the list column
  effect_size <- effect_size %>% select(-cohen_d)

  write_csv(effect_size, save_dir_filename)

  return(save_dir_filename)
}
