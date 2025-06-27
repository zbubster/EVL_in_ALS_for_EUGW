#---#---#---#---#---#---#---#---#---#---#---#---#

# FSB analysis

#---#---#---#---#---#---#---#---#---#---#---#---#
# This code computes statistics based on presence of focal FSB groups within EVL (Natura2000) sites.
# total_area ... what is an area of mapped features within (relation T********) EVL
# fsb_area ... what is an area of focal FSB features
# fsb_ratio ... ratio between total_area and fsb_area (which part of total mapped area within EVL is covered by focal FSBs [0-1])

#---#---#---#---#---#---#---#---#---#---#---#---#
# Relad data, if needed
vmb_joined <- st_read("data/processing/vmb_joined.gpkg")

#---#---#---#---#---#---#---#---#---#---#---#---#
# Target of analysis
fsb_target <- c("T", "M", "R", "A")

# Compute statistics
fsb_summary <- vmb_joined %>%
  mutate(fsb_in = FSB %in% fsb_target) %>%
  group_by(SITECODE) %>%
  summarise(
    total_area = sum(area, na.rm = TRUE), # celkova plocha, pro kterou mame data (na zacatky byly z VMB vylouceny polygony s atributem -1)
    fsb_area = sum(area[fsb_in], na.rm = TRUE), # plocha, kterou v ramci EVL zabiraji zajmove FSB
    fsb_ratio = fsb_area / total_area # podil celkove plochy EVL, kterou zabiraji zajmove FSB
  ) %>%
  arrange(desc(fsb_ratio))

#---#---#---#---#---#---#---#---#---#---#---#---#
# save results

# create /results
if(!dir.exists("data/results")){
  dir.create("data/results", recursive = T)
}

# write layer
st_write(fsb_summary, "data/results/fsb.shp")