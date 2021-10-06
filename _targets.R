library(targets)
library(tarchetypes)
library(magrittr)
library(future)
library(future.callr)

source("R/simulate.R")
source("R/fit.R")
source("R/summarize.R")
source("R/visualize.R")
source("R/utils.R")

tar_option_set(packages = c("tidyverse", "here", "gasr", "glue", "ardea",
                            "ggtext"))

# Load the Arial font for Ardea themed plots
extrafont::loadfonts(device = "win", quiet = TRUE)

# Parallelize targets locally with the future package
# https://books.ropensci.org/targets/hpc.html#future
future::plan(callr)

# Since a lot of data will be generated, use the shared drive to store data,
#  models and results
project_dir <- file.path("G:", "Shared drives", "Current Projects",
                      "GAS Data Simulations", "isoqol2021-gas-sim")
data_dir <- file.path(project_dir, "data")
models_dir <- file.path(project_dir, "models")
results_dir <- file.path(project_dir, "results")

# Define the simulation parameters
n_subjects <- c(40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150)
delta <- c(0.2, 0.3, 0.4, 0.5, 0.6, 0.8)
n_goals <- c(1, 2, 3, 4, 5, 6, 7)
n_sim <- 1e4

# Combine all parameters into a data frame
sim_params <-
  tidyr::crossing(
    n_subjects, delta, n_goals, n_sim
  ) %>%
  dplyr::mutate(
    param_string = sim_params_string(n_subjects, delta, n_goals, n_sim)
  )

# Define the target mappings
tar_mappings <-
  tar_map(
    unlist = FALSE,
    values = sim_params,
    names = "param_string",
    # Run the simulations and save to file
    tar_target(
      sim_data,
      simulate(n_subjects, delta, n_goals, n_sim,
               save_dir = data_dir, save_filename = param_string),
      format = "file"
    ),
    # Run t-tests and save to file
    tar_target(
      sim_data_ttest,
      fit_ttest(sim_data,
                save_dir = models_dir, save_filename = param_string),
      format = "file"
    ),
    # Compute power
    tar_target(
      sim_ttest_power,
      calculate_power(sim_data_ttest)
    ),
    # Compute effect sizes
    tar_target(
      sim_effect_size,
      summarize_effect_size(sim_data_ttest)
    )
  )

# Define target combinations
tar_combinations <- list(
  # Combine the power into a single data frame
  tar_combine(
    ttest_power,
    tar_mappings[[3]],
    command = dplyr::bind_rows(!!!.x)
  ),
  # Combine the effect sizes into a single data frame
  tar_combine(
    effect_size,
    tar_mappings[[4]],
    command = dplyr::bind_rows(!!!.x)
  )
)

# Define the target pipeline to be executed
list(
  tar_mappings,
  tar_combinations,

  # Save the power
  tar_target(
    ttest_power_file,
    save_ttest_power(ttest_power, save_dir = results_dir),
    format = "file"
  ),

  # Save the effect sizes
  tar_target(
    effect_size_file,
    save_effect_size(effect_size, save_dir = results_dir),
    format = "file"
  ),

  # Compute power differences
  tar_target(
    ttest_power_diff,
    calculate_power_diff(ttest_power, save_dir = results_dir)
  ),

  # Compute the minimum number of goals for specified power
  tar_target(
    ttest_power_min_goals,
    calculate_power_min_goals(ttest_power, save_dir = results_dir)
  ),

  # Plot power vs number of subjects, for difference numbers of goals
  tar_target(
    ttest_power_diff_plot_n_goals123,
    plot_power_n_subjects_n_goals_delta(ttest_power, ttest_power_diff,
                                        plot_n_goals = c(1, 2, 3),
                                        save_dir = results_dir)
  ),
  tar_target(
    ttest_power_diff_plot_n_goals1234,
    plot_power_n_subjects_n_goals_delta(ttest_power, ttest_power_diff,
                                        plot_n_goals = c(1, 2, 3, 4),
                                        save_dir = results_dir),
  ),

  # Plot effect size
  tar_target(
    effect_size_plot,
    plot_effect_size(effect_size),
  )
)
