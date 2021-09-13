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

