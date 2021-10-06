# isoqol2021-gas-sim

Code for the ISOQOL 2021 poster: Minimum number of goals per subject in goal attainment scaling trials: a simulation study.

The poster itself is produced and hosted in the iPoster platform here: https://isoqol2021-isoqol.ipostersessions.com/default.aspx?s=59-C4-73-2F-1E-C3-15-83-6C-72-85-0D-6A-A9-A9-90#


# Abstract

## Aims

Goal attainment scaling (GAS) is a patient-centric outcome measure that captures meaningful change through personally identified goals of treatment. Traditionally, it is recommended to set a minimum of three goals per subject in a clinical trial. Depending on the subject population and time constraints, however, it may not be feasible to reach this minimum number. Our aim was to investigate the effect of number of goals per subject on statistical power using data simulation techniques.

## Methods

We employed a probabilistic model introduced by Urach et al. (2019) for generating randomized parallel group GAS endpoint data. This model allows for adjustment of many study parameters, but for this analysis we varied only the total number of subjects m (from 20 to 100), treatment effect size δ (from 0.4 to 0.8), and the parameter of interest: number of goals per subject n (from 1 to 7). For each set of parameters, 1000 parallel group trials were simulated and a two-sided t-test was performed on standardized T-scores. Power was computed as the percentage of simulations detecting a statistically significant treatment effect at α = 0.05.

## Results

The gain in statistical power ranged from 8-20% for 2 goals per subject, compared to 1 goal per subject. The difference between 3 and 2 goals per subject was less pronounced, with power increases ranging from 2-11%. This pattern of diminishing returns continued for more than 3 goals, e.g. 0-8% gains from 4 vs 3 goals per subject. With 3 goals per subject, the minimum sample size required to reach 80% was found to be >100, 60 ,and 40 subjects for effect sizes δ = 0.4, 0.6, and 0.8 respectively.

## Conclusions

The power to detect a treatment effect increased with increasing number of goals per subject. The gains in power had diminishing returns, however, with the most substantial increase from 1 to 2 goals per subject. For the moderate-large effect sizes considered here, the traditional 3 goal minimum reached 80% power with sample sizes ranging from 40 to 100+ subjects.

# Instructions

This project uses three key packages:

* `renv`
    * Manages project-local R dependencies
    * The packages and versions used for this project are listed in the `renv.lock` file
    * To restore the project dependencies from the lockfile, run `renv::restore()`
    * To use new packages/versions, run `renv::snapshot()` to overwrite the existing lockfile
* `targets`
    * A toolkit for reproducible project workflows
    * Saves a lot of time on computation by skipping up-to-date tasks
    * Read more about `targets` here: https://books.ropensci.org/targets/
    * The key file is `_targets.R` which lists every step in the analysis pipeline
        * To get it working on your machine, the `project_dir` variable will likely need to be changed -- choose somewhere with lots of storage, as the size of all the raw data was 40-50 GB
        * `tar_make()` runs the pipeline from starts to finish, but *will take forever to run* due to the number of parameters being simulated (every combination of `n_subjects`, `n_goals`, `delta`, is run `n_sim` times) so I recommend reducing these parameters as a first test run
        * To speed up the simulations drastically, take advantage of parallel processing with the `tar_make_future(workers = 8)`, with the `workers` argument set to the number of processor cores you want to use
    * After running the pipeline, objects are accessed with the `tar_load()` function
        * For example, execute `tar_load(ttest_power_diff_plot_n_goals1234)` to load the figure of power vs number of subjects for 1-4 goals per subject
* `gasr`
    * Used to simulate GAS data
    * See the GitHub README for more information: https://github.com/taylordunn/gasr
