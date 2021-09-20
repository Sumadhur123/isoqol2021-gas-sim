plot_power_n_subjects_n_goals_delta <- function(
  ttest_power, ttest_power_diff,
  # Which parameters to plot
  plot_n_goals = c(1, 2, 3),
  plot_delta = c(0.2, 0.3, 0.4, 0.5),
  save_dir = NULL
) {
  ttest_power <- ttest_power %>%
    filter(sim_n_goals %in% plot_n_goals,
           sim_delta %in% plot_delta) %>%
    mutate(
      sim_delta_label = str_c("\u03b4 = ", sim_delta) %>% fct_inorder()
    )

  ttest_power_diff <- ttest_power_diff %>%
    filter(n_goals1 %in% plot_n_goals, n_goals2 %in% plot_n_goals,
           sim_delta %in% plot_delta) %>%
    # Only show the power difference between adjacent numbers of goals
    filter(n_goals2 == n_goals1 + 1) %>%
    group_by(n_goals1, n_goals2) %>%
    mutate(
      median_power_diff = median(power_diff),
      mean_power_diff = mean(power_diff),
      min_power_diff = min(power_diff), max_power_diff = max(power_diff),
      sd_power_diff = sd(power_diff)
    ) %>%
    mutate(
      n_goals_label = glue(
        "{n_goals1} \u2192 {n_goals2} goals: ",
        "+{scales::percent(median_power_diff, suffix = '')} ",
        "[{scales::percent(min_power_diff, suffix = '')}-",
        "{scales::percent(max_power_diff, suffix = '')}]%"
      ),
      sim_delta_label = str_c("\u03b4 = ", sim_delta) %>% fct_inorder()
    )

  # Use these colors, in this particular order, to distinguish the power diffs
  p_colors <-
    ardea_colors(c("magenta", "purple", "blue_gray" ,"dark_purple", "blue",
                   "pink", "cyan"))
  n_goals_combinations <- unique(ttest_power_diff$n_goals_label)
  p_colors <- p_colors[1:length(n_goals_combinations)]

  p_title <- glue_collapse(
    c(
      "Power difference: median [range]",
      map2_chr(
        unique(ttest_power_diff$n_goals_label), p_colors,
        ~glue("<span style='color:{.y}'>{.x}</span>")
      )
    ),
    sep = "<br>"
  )

  p <- ttest_power %>%
    ggplot(aes(x = sim_n_subjects)) +
    geom_point(aes(y = power), size = 2) +
    geom_line(aes(y = power, lty = factor(sim_n_goals)), size = 1) +
    geom_hline(yintercept = 0.8) +
    geom_ribbon(
      data = ttest_power_diff,
      aes(ymin = power1, ymax = power2, fill = n_goals_label),
      show.legend = FALSE, alpha = 0.5
    ) +
    facet_wrap(~sim_delta_label, ncol = 2) +
    theme_ardea() +
    scale_y_continuous("Power",
                       breaks = c(0, 0.5, 0.8, 1.0), labels = scales::percent) +
    scale_fill_manual(values = p_colors) +
    labs(x = "Number of subjects, m", y = "Power", lty = "Goals per subject",
         title = p_title) +
    theme(legend.position = "none",
          plot.title = element_markdown())

  if (!is.null(save_dir)) {
    save_dir_filename <- file.path(
      save_dir,
      str_c("power-diff_n-goals", str_c(plot_n_goals, collapse = "-"), "_",
            "delta", str_c(plot_delta, collapse = "-"), ".png")
    )
    ggsave(
      save_dir_filename, plot = p, width = 6, height = 6, dpi = 300,
      bg = "white"
    )
  }

  return(p)
}

plot_minimum_goals_power <- function(ttest_power_min_goals, save_dir = NULL) {
  p <- ttest_power_min_goals %>%
    ggplot(aes(x = factor(sim_delta), y = factor(sim_n_subjects))) +
    geom_tile(aes(fill = min_n_goals), color = "white") +
    geom_text(aes(label = min_n_goals), color = "white", size = 8) +
    geom_text(
      data = . %>% filter(!is.na(power)),
      aes(label = scales::percent(power, 1)),
      color = "white", size = 2.5, nudge_y = -0.3
    ) +
    scale_x_discrete("Effect size, \u03b4", expand = c(0, 0), position = "top") +
    scale_y_discrete("Number of subjects, m", expand = c(0, 0)) +
    scale_fill_viridis_d(option = "plasma", end = 0.9) +
    labs(title = "Minimum number of goals required to reach 80% power") +
    theme_ardea() +
    theme(legend.position = "none")

  if (!is.null(save_dir)) {
    save_dir_filename <- file.path(save_dir, "power_min-goals.png")

    ggsave(
      save_dir_filename, plot = p, width = 6, height = 10, dpi = 300,
      bg = "white"
    )
  }

  return(p)
}

#' This plot can be used to calibrate simulation effect size (delta)
#' towards empirical effect size (Cohen's d)
plot_effect_size <- function(effect_size) {
  effect_size %>%
    ggplot(aes(x = sim_delta, y = cohen_d_mean, color = factor(sim_n_goals))) +
    geom_linerange(aes(ymin = cohen_d_mean - cohen_d_sd,
                       ymax = cohen_d_mean + cohen_d_sd)) +
    geom_point() +
    geom_line() +
    geom_abline(slope = 1, intercept = 0, lty = 2) +
    facet_grid(sim_n_goals ~ sim_n_subjects) +
    scale_color_viridis_d() +
    scale_x_continuous(breaks = c(0.2, 0.5, 0.8), limits = c(0.1, 0.9)) +
    scale_y_continuous(breaks = c(0.2, 0.5, 0.8)) +
    coord_cartesian(ylim = c(0, 1.2)) +
    theme_ardea() +
    theme(legend.position = "none") +
    labs(
      title = "Mean (SD) effect size (Cohen's d) vs simulated effect size",
      subtitle = "Columns = number of subjects | Rows = number of goals",
      x = "Simulated effect size",
      y = "Mean (SD) effect size from 10^4 simulations"
    )
}
