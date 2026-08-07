

# import function(s) ------------------------------------------------------
## import meta-data/data files from Google Drive 

import_gsheet = function(dat){
  googlesheets4::read_sheet(dat) %>% mutate_all(as.character)
}

#
# PROCESS GWC, LOI --------------------------------------------------------

process_moisture = function(moisture_data){
  #  moisture_processed = 
  moisture_data %>% 
    # keep only relevant columns
    dplyr::select(sample_label, starts_with("wt")) %>% 
    # make all (most) columns numeric 
    mutate_at(vars(-sample_label), as.numeric)  %>% 
    filter(!is.na(sample_label)) %>% 
    # calculate GWC
    # ((wet-dry)/dry) * 100
    mutate(gwc_percent = 100 * (wt_crucible_MOIST_SOIL_g - wt_crucible_OVEN_DRY_SOIL_g)/(wt_crucible_OVEN_DRY_SOIL_g - wt_crucible_g),
           gwc_percent = round(gwc_percent, 2)) %>% 
    filter(!is.na(gwc_percent)) %>% 
    dplyr::select(sample_label, gwc_percent) %>% 
    mutate(analysis = "GWC")
}
process_loi = function(moisture_data){
  
  #  moisture_processed = 
  moisture_data %>% 
    # keep only relevant columns
    dplyr::select(sample_label, starts_with("wt")) %>% 
    # make all (most) columns numeric 
    mutate_at(vars(-sample_label), as.numeric)  %>% 
    filter(!is.na(sample_label)) %>% 
    # calculate LOI
    # ((dry-combusted)/dry) * 100
    mutate(loi_percent = 100 * (wt_crucible_OVEN_DRY_SOIL_g - wt_crucible_COMBUSTED_SOIL_g)/(wt_crucible_OVEN_DRY_SOIL_g - wt_crucible_g),
           loi_percent = round(loi_percent, 2),
           loi_percent = case_when(loi_percent < 0 ~ 0, .default = loi_percent)) %>% 
    filter(!is.na(loi_percent)) %>% 
    dplyr::select(sample_label, loi_percent) %>% 
    mutate(analysis = "LOI")
  
}

#
# PROCESS PH --------------------------------------------------------------

process_ph = function(pH_data){
  
 # pH_samples = 
  pH_data %>% 
    janitor::clean_names() %>% 
    dplyr::select(sample_label, p_h, cond_us_cm) %>% 
    rename(spConductance_uscm = cond_us_cm,
           pH = p_h) %>% 
    mutate_at(vars(-sample_label), as.numeric)  %>% 
    filter(grepl("COMPASS", sample_label)) %>% 
    filter(!is.na(pH) | !is.na(spConductance_uscm)) %>% 
    mutate(analysis = "PH")
  
}

#

# PROCESS WSOC ------------------------------------------------------------

import_weoc_data = function(FILEPATH, PATTERN){
  
  filePaths_weoc <- list.files(path = FILEPATH, pattern = PATTERN, full.names = TRUE)
  weoc_dat <- do.call(bind_rows, lapply(filePaths_weoc, function(path) {
    df <- read_tsv(path, skip = 10)
    df}))
  
  
}
process_weoc = function(weoc_data, analysis_key, moisture_processed, subsampling){
  
  npoc_processed = 
    weoc_data %>% 
    # remove skipped samples
    filter(!`Sample ID` %in% "skip") %>% 
    # keep only relevant columns and rename them
    dplyr::select(`Sample Name`, `Result(NPOC)`) %>% 
    rename(sample_label = `Sample Name`,
           npoc_mgL = `Result(NPOC)`) %>% 
    # keep only sample rows 
    filter(grepl("COMPASS_", analysis_ID)) %>% 
    # join the analysis key to get the sample_label
#    left_join(analysis_key %>% dplyr::select(analysis_ID, sample_label, NPOC_dilution)) %>%
    # do blank/dilution correction
    mutate(blank_mgL = case_when(sample_label == "blank-filter" ~ npoc_mgL)) %>% 
    fill(blank_mgL, .direction = c("up")) %>% 
    mutate(NPOC_dilution = as.numeric(NPOC_dilution),
           npoc_corr_mgL = (npoc_mgL) * NPOC_dilution) %>% 
    # join gwc and subsampling weights to normalize data to soil weight
    left_join(moisture_processed) %>% 
    left_join(subsampling %>% dplyr::select(notes, sample_label, WSOC_g) %>% drop_na()) %>% 
    rename(fm_g = WSOC_g) %>% 
    mutate(od_g = fm_g/((gwc_perc/100)+1),
           soilwater_g = fm_g - od_g,
           npoc_ug_g = npoc_corr_mgL * ((40 + soilwater_g)/od_g),
           npoc_ug_g = round(npoc_ug_g, 2)) %>% 
    dplyr::select(sample_label, npoc_corr_mgL, npoc_ug_g, notes)
  
  npoc_samples = 
    npoc_processed %>% 
    filter(grepl("COMPASS", sample_label))%>% 
    mutate(analysis = "NPOC")
  
  npoc_samples
}

