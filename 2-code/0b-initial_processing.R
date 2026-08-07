

sample_key = read_sheet("https://docs.google.com/spreadsheets/d/13c1f_QSv73ez7DTSZqa9rjX0d-ieopQvwuftm0lzr4w/edit?gid=0#gid=0") %>% 
  mutate_all(as.character)

sample_key_subset = 
  sample_key %>% 
  dplyr::select(sample_label, region, site, transect, tree_number, horizon, depth) %>% 
  filter(!is.na(sample_label)) %>% 
  mutate(transect = tolower(transect),
         site = recode(site, "Sweethall" = "SWH"),
         region = recode(region, "WLE" = "Erie", "CB" = "Chesapeake")) %>% 
  drop_na()
sample_key_subset[sample_key_subset == "NULL"] <- NA

## export
sample_key_subset %>% write.csv("1-data/sample_key.csv", row.names = FALSE, na = "")


subsampling_weights = read_sheet("https://docs.google.com/spreadsheets/d/10tRwmPvEdfuOW_SI55oXR2FQIQvo4SK-XdpH8AvaJl4/edit?gid=0#gid=0", 
                                 sheet = "subsampling_weights") %>% mutate_all(as.character)
subsampling_weights_subset = 
  subsampling_weights %>% 
 # filter(!is.na(site)) %>% 
  dplyr::select(sample_label, ends_with(c("_g", "mL")), WSOC_dilution, notes) %>% 
  mutate_at(vars(ends_with("_g")), as.numeric) %>% 
  filter(grepl("COMPASS", sample_label))

## export
subsampling_weights_subset %>% write.csv("1-data/subsampling_weights.csv", row.names = F, na = "")