library(targets)

tar_option_set(packages = c("tidyverse", "here", "goalnavr"))

# End this file with a list of target objects.
list(
  tar_target(data, data.frame(x = sample.int(100), y = sample.int(100))),
)
