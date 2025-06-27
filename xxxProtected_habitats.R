################################################################################
################################################################################
################################################################################
# habitat_codes & kod_fenomenu
# jake predmety ochrany jsou v danych EVL jak zastoupeny

kod_map <- evl %>%
  st_drop_geometry() %>%
  select(SITECODE, Kod_fenomenu) %>%
  distinct()

# vytvoreni vsech kombinaci HABIT_CODES a Kod_fenomenu podle SITECODE
vmb_kod <- left_join(vmb_joined, kod_map, by = "SITECODE")

# je habitat v danem EVL chraneny? T/F
vmb_kod <- vmb_kod %>%
  mutate(kod_match = HABIT_CODES == Kod_fenomenu)

# agregace po SITECODE a Kod_fenomenu
habitat_detailed <- vmb_kod %>%
  group_by(SITECODE, Kod_fenomenu) %>%
  summarise(
    total_area_habit = sum(area, na.rm = TRUE),
    match_area_habit = sum(area[kod_match], na.rm = TRUE),
    match_ratio_habit = match_area_habit / total_area_habit
  ) %>%
  arrange(SITECODE, desc(match_ratio_habit))

st_write(habitat_detailed, "data/results/hab_detialed.gpkg")
