

# import function(s) ------------------------------------------------------
## import meta-data/data files from Google Drive 

import_gsheet = function(dat){
  googlesheets4::read_sheet(dat) %>% mutate_all(as.character)
}


# refactor/reorder functions ----------------------------------------------
## functions to set the order of factors

reorder_horizon = function(dat){
  dat %>% 
    mutate(horizon = factor(horizon, levels = c("O", "A", "A2", "E", "B")))
}

reorder_depth = function(dat){
  dat %>% 
    mutate(depth = factor(depth, levels = c("surface", "subsurface")))
}

reorder_transect = function(dat){
  dat %>% 
    mutate(transect = factor(transect, levels = c("upland", "swamp", "transition", "wetland")))
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
    mutate(GWC_percent = 100 * (wt_crucible_MOIST_SOIL_g - wt_crucible_OVEN_DRY_SOIL_g)/(wt_crucible_OVEN_DRY_SOIL_g - wt_crucible_g),
           GWC_percent = round(GWC_percent, 2)) %>% 
    filter(!is.na(GWC_percent)) %>% 
    dplyr::select(sample_label, GWC_percent) %>% 
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
    rename(SOM_percent = loi_percent) %>% 
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
process_weoc = function(weoc_data, moisture_processed, subsampling){
  
  npoc_processed = 
    weoc_data %>% 
    # remove skipped samples
    filter(!`Sample ID` %in% "skip") %>% 
    # keep only relevant columns and rename them
    dplyr::select(`Sample ID`, `Result(NPOC)`) %>% 
    rename(sample_label = `Sample ID`,
           npoc_mgL = `Result(NPOC)`) %>% 
    # keep only sample rows 
    filter(grepl("COMPASS|CMPS", sample_label)) %>% 
    # do blank/dilution correction
 #   mutate(blank_mgL = case_when(sample_label == "blank-filter" ~ npoc_mgL)) %>% 
 #    fill(blank_mgL, .direction = c("up")) %>% 
    left_join(subsampling %>% dplyr::select(sample_label, WSOC_g, WSOC_mL, WSOC_dilution) %>% drop_na()) %>% 
    mutate(WSOC_dilution = as.numeric(WSOC_dilution),
           npoc_corr_mgL = (npoc_mgL) * WSOC_dilution) %>% 
    # join gwc and subsampling weights to normalize data to soil weight
    left_join(moisture_processed) %>% 
    rename(fm_g = WSOC_g) %>% 
    mutate(od_g = fm_g/((GWC_percent/100)+1),
           soilwater_g = fm_g - od_g,
           weoc_ug_g = npoc_corr_mgL * ((40 + soilwater_g)/od_g),
           weoc_ug_g = round(weoc_ug_g, 2)) %>% 
    dplyr::select(sample_label, npoc_corr_mgL, weoc_ug_g)
  
  npoc_samples = 
    npoc_processed %>% 
    filter(grepl("COMPASS", sample_label)) %>% 
    mutate(analysis = "WEOC") %>% 
    rename(WEOC_ugg = weoc_ug_g)
  
  npoc_samples
}



#

# COMBINED CHEMISTRY DATA -------------------------------------------------

combine_data = function(moisture_processed, pH_processed, loi_processed, 
                        weoc_processed, sample_key){
  
  df_list = list(moisture_processed, pH_processed, loi_processed, 
                 weoc_processed)
  
  data_combined_all_horizons = 
    df_list %>% reduce(full_join) %>% 
    dplyr::select(-ends_with(c("_ppm", "_mgL", "_flag"))) %>% 
    pivot_longer(-c(sample_label, analysis)) %>% 
    drop_na() %>% 
    left_join(sample_key) %>% 
    reorder_transect() %>% 
    reorder_horizon() %>% 
    reorder_depth() %>% 
    force() 
  
  data_combined_all_horizons
  
}

make_data_wide = function(data_combined, sample_key){
  
  #data_combined_wide = 
  data_combined %>% 
    dplyr::select(sample_label, analysis, name, value) %>% 
    #separate(name, sep = "_", into = "variable", remove = F) %>% 
    #mutate(name = paste0(variable, " (", analysis, ")")) %>% 
    dplyr::select(sample_label, name, value) %>% 
    pivot_wider(names_from = "name") %>% 
    left_join(sample_key) %>% 
    dplyr::select(sample_label, region, site, transect, tree_number, depth, horizon, everything()) %>% 
    force()
  
}