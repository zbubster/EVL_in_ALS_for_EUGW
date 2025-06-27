#---#---#---#---#---#---#---#---#---#---#---#---#

# Combine outputs

#---#---#---#---#---#---#---#---#---#---#---#---#
# Relad data, if needed
evl_union <- st_read("data/processing/evl_union.gpkg")
fsb_summary <- st_read("data/results/datum.shp")
datum_summary <- st_read("data/results/fsb.shp")

#---#---#---#---#---#---#---#---#---#---#---#---#
# Merge outputs with geometry of EVLs
summary_combined <- evl_union %>%
  select(SITECODE, NAZEV, SHAPE_AREA) %>%
  left_join(st_drop_geometry(fsb_summary), by = "SITECODE") %>%
  left_join(st_drop_geometry(datum_summary), by = "SITECODE")

#---#---#---#---#---#---#---#---#---#---#---#---#
# Save output

# create /out
if(!dir.exists("data/out")){
  dir.create("data/out", recursive = T)
}

# write layer
st_write(summary_combined, "data/out/EVL_statsum.gpkg")