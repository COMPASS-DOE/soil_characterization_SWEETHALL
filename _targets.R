# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
# library(tarchetypes) # Load other packages as needed.

# Set target options:
tar_option_set(
  packages = c("tibble", "tidyverse", "tarchetypes"), # packages that your targets need to run
  format = "rds" # default storage format
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source("2-code/0-packages.R")
#tar_source("2-code/0b-initial_processing.R")
tar_source("2-code/1-processing.R")
# tar_source("other_functions.R") # Source other scripts as needed.

# Replace the target list below with your own:
list(
  
  # sample metadata
  tar_target(sample_key_data, "1-data/sample_key.csv", format = "file"),
  tar_target(sample_key, read.csv(sample_key_data)),
  tar_target(subsampling_data, "1-data/subsampling_weights.csv", format = "file"),
  tar_target(subsampling, read.csv(subsampling_data)),
  
  tar_target(moisture_data, import_gsheet("https://docs.google.com/spreadsheets/d/1b40OLAx637_Pc_ERC1aHQtWN_mTpnbfqm-3Em5YV1l4/")),
  tar_target(moisture_processed, process_moisture(moisture_data)),
  tar_target(loi_processed, process_loi(moisture_data)),
  
  tar_target(pH_data, import_gsheet("https://docs.google.com/spreadsheets/d/1rztTEWvlArXmYQUXv5M4DrfSHT8d0G0A9Jm97VBuIgg/")),
  tar_target(pH_processed, process_ph(pH_data)),
  
  tar_target(weoc_data, import_weoc_data(FILEPATH = "1-data/raw/wsoc", PATTERN = "Summary_Raw")),
  tar_target(weoc_processed, process_weoc(weoc_data, moisture_processed, subsampling)),
  
# tar_quarto(
#   report,
#   path = "3-reports/Untitled.qmd",
#   quiet = FALSE),
   
  NULL
  
)
