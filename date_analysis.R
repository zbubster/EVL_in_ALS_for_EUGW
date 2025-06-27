#---#---#---#---#---#---#---#---#---#---#---#---#

# Date analysis

#---#---#---#---#---#---#---#---#---#---#---#---#
# This code computes statistics based on age of the data within separate EVLs.
# avg_year ... mean all data
# newest ... freshest data
# oldest ... oldest data
# avg_year_fsb ... mean age of data from focal FSB groups
# newest_fsb ... newest focal FSB record
# oldest_fsb ... oldest focal FSB record

#---#---#---#---#---#---#---#---#---#---#---#---#
# Relad data, if needed
vmb_joined <- st_read("data/processing/vmb_joined.gpkg")

#---#---#---#---#---#---#---#---#---#---#---#---#
# Target of analysis
fsb_target <- c("T", "M", "R", "A")

# Compute needed cols
# year ... simplify original DATUM col
# fsb_in ... if polygon contain relevant FSB cathegory
vmb_joined <- vmb_joined %>%
  mutate(
    year = as.numeric(format(as.Date(DATUM), "%Y")),
    fsb_in = FSB %in% fsb_target
  )

# Compute statistics
datum_summary <- vmb_joined %>%
  group_by(SITECODE) %>%
  summarise(
    avg_year = mean(year, na.rm = TRUE),
    newest = max(year, na.rm = TRUE),
    oldest = min(year, na.rm = TRUE),
    avg_year_fsb = ifelse(all(is.na(year[fsb_in])), NA, mean(year[fsb_in], na.rm = TRUE)),
    newest_fsb = ifelse(all(is.na(year[fsb_in])), NA, max(year[fsb_in], na.rm = TRUE)),
    oldest_fsb = ifelse(all(is.na(year[fsb_in])), NA, min(year[fsb_in], na.rm = TRUE))
  ) %>%
  arrange(desc(avg_year))

#---#---#---#---#---#---#---#---#---#---#---#---#
# Save results

# create /out
if(!dir.exists("data/out")){
  dir.create("data/out", recursive = T)
}

# write layer
st_write(datum_summary, "data/results/datum.shp")