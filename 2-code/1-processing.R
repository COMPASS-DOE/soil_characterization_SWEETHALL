

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

