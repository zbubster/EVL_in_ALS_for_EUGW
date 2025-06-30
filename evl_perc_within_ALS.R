# převod als na sf
als_sf <- st_as_sf(als)

# průnik polygonů
inter <- st_intersection(evl_union, als_sf)

# spočítat plochu průniku
inter$inter_area <- as.numeric(st_area(inter))

# sečíst plochy podle SITECODE
inter_sum <- inter %>%
  group_by(SITECODE) %>%
  summarise(area_inside = sum(inter_area))

# připojit zpět k původní vrstvě
evl_union_joined <- evl_union %>%
  left_join(st_drop_geometry(inter_sum), by = "SITECODE") %>%
  mutate(
    area_inside = ifelse(is.na(area_inside), 0, area_inside),
    perc_inside = (area_inside / SHAPE_AREA) * 100
  )

# výpis
evl_union_joined <- evl_union_joined %>%
  select(SITECODE, area_inside_ALS = area_inside, perc_inside_ALS = perc_inside)

#---#---#---#---#---#---#---#---#---#---#---#---#
# Save results

# create /results
if(!dir.exists("data/results")){
  dir.create("data/results", recursive = T)
}

# write layer
st_write(evl_union_joined, "data/results/evl_within_als.gpkg")
