#---#---#---#---#---#---#---#---#---#---#---#---#

# Recent target FSB area within EVl

#---#---#---#---#---#---#---#---#---#---#---#---#
# libraries
source("scripts/knihovnik.R")
knihovnik(c("terra", "dplyr", "RCzechia", "sf"))

#---#---#---#---#---#---#---#---#---#---#---#---#

#---#---#---#---#---#---#---#---#---#---#---#---#
# Reload data, if needed
evl_union <- st_read("data/processing/evl_union.gpkg")
vmb_joined <- st_read("data/processing/vmb_joined.gpkg")

#---#---#---#---#---#---#---#---#---#---#---#---#

fsb_target <- c("T", "M", "R", "A")

vmb_target <- vmb_joined %>%
  filter(FSB %in% fsb_target)

#---#---#---#---#---#---#---#---#---#---#---#---#

intersect_fsb_union <- st_intersection(evl_union, vmb_target)

# plocha pruniku
intersect_fsb_union$area_overlap <- st_area(intersect_fsb_union)

#---#---#---#---#---#---#---#---#---#---#---#---#

target_area_summary_union <- intersect_fsb_union %>%
  st_drop_geometry() %>%
  group_by(SITECODE) %>%
  summarise(
    target_area = sum(as.numeric(area_overlap), na.rm = TRUE)
  )


names(evl_union)[names(evl_union) == "mean_SHAPE_AREA"] <- "SHAPE_AREA"
# spojit s originalnimi daty
X_evl_union <- left_join(evl_union, target_area_summary_union, by = "SITECODE")

# nahradit NA nulou (evl bez prekryvu se zajmovymi fsb)
X_evl_union$target_area[is.na(X_evl_union$target_area)] <- 0

X_evl_union <- X_evl_union %>%
  select(SITECODE, recent_fsb_area = target_area)

#---#---#---#---#---#---#---#---#---#---#---#---#
# Save results

# create /results
if(!dir.exists("data/results")){
  dir.create("data/results", recursive = T)
}

# write layer
st_write(X_evl_union, "data/results/recent_fsb.gpkg")
