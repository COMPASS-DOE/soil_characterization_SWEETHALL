

# import function(s) ------------------------------------------------------
## import meta-data/data files from Google Drive 

import_gsheet = function(dat){
  googlesheets4::read_sheet(dat) %>% mutate_all(as.character)
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

