# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
# library(tarchetypes) # Load other packages as needed.

# Set target options:
tar_option_set(
  packages = c("tibble", "tidyverse"), # packages that your targets need to run
  format = "rds" # default storage format
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source("2-code/0-packages.R")
tar_source("2-code/1-processing.R")
# tar_source("other_functions.R") # Source other scripts as needed.

# Replace the target list below with your own:
list(
  tar_target(pH_data, import_gsheet("https://docs.google.com/spreadsheets/d/1rztTEWvlArXmYQUXv5M4DrfSHT8d0G0A9Jm97VBuIgg/")),
  tar_target(pH_processed, process_ph(pH_data)),
  
  
  
  NULL
  
)
