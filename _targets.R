library(targets)
library(tarchetypes)
library(magrittr)
library(future)
library(future.callr)

source("R/simulate.R")
source("R/fit.R")
source("R/summarize.R")
source("R/utils.R")

tar_option_set(packages = c("tidyverse", "here", "gasr", "glue", "ardea"))

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
n_subjects <- c(40, 50, 60, 70, 80)
delta <- c(0.4, 0.6, 0.8)
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
    tar_target(
      sim_data,
      simulate(n_subjects, delta, n_goals, n_sim,
               save_dir = data_dir, save_filename = param_string),
      format = "file"
    ),
    tar_target(
      sim_data_ttest,
      fit_ttest(sim_data,
                save_dir = models_dir, save_filename = param_string),
      format = "file"
    ),
    tar_target(
      sim_ttest_power,
      summarize_power(sim_data_ttest,
                      save_dir = results_dir)
    )
  )

# Define target combinations
tar_combinations <- tar_combine(
  ttest_power,
  tar_mappings[[3]],
  command = dplyr::bind_rows(!!!.x)
)

# Define the target pipeline to be executed
list(
  tar_mappings,
  tar_combinations
)
