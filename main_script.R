# selection EVL in ALS zone

source("scripts/knihovnik.R")

vector <- vect("data/VMB/biotop_habitat.shp")
what_to_filter <- c("moz.", "-")
vector <- vector[!toupper(vector$FSB) %in% what_to_filter,]

vmb <- vector; rm(vector); gc()
evl <- vect("data/EVL/evl_ochrana_stanoviste_kodhabitatu.gpkg")
als <- vect("data/ALS/ALS_extracted/ALS.shp")

source("scripts/CRS.R")
check_same_crs(c(vmb, evl, als)) # must be class vector/list
layers_list <- harmonize_crs(list(vmb = vmb, evl = evl, als = als)) # must be class list
check_same_crs(layers_list)

vmb <- layers_list[["vmb"]]
evl <- layers_list[["evl"]]
als <- layers_list[["als"]]
rm(layers_list); gc()

# check_same_crs(c(vmb, evl, als, hranice))

writeVector(vmb, "data/processing/vmb.gpkg", overwrite = T)
writeVector(evl, "data/processing/evl.gpkg", overwrite = T)
writeVector(als, "data/processing/als.gpkg", overwrite = T)
rm(vmb, evl, als); gc()

################################################################################
# reboot

source("scripts/knihovnik.R")

vmb <- vect("data/processing/vmb.gpkg")
evl <- vect("data/processing/evl.gpkg")
als <- vect("data/processing/als.gpkg")

## spatial relation DE-9IM: T******** (intersect)

# Vyber pouze tech EVL, ktere jsou ve vztahu s ALS zonou
idx <- relate(evl, als, "T********")
evl <- evl[idx == T, ]

# Slouceni radku EVL, aggN reprezentuje pocet chranenych typu biotopu v danem EVL
evl_union <- aggregate(evl, by = "SITECODE")

# Vyber segmentu VMB, ktere maji vztah s vybranymi EVL
idx <- relate(vmb, evl_union, "T********", pairs = TRUE) # Vytvoření indexu všech překryvů (vmb vs. evl_union)
vmb2 <- vmb[unique(idx[,1]), ] # Výběr všech unikátních indexů z vmb, které mají nějaký vztah z množiny T*********

# zapis vysledku
writeVector(vmb2, "data/processing/vmb_evl.gpkg", overwrite = T)
writeVector(evl, "data/processing/evl_als.gpkg", overwrite = T)
writeVector(evl_union, "data/processing/evl_union.gpkg", overwrite = T)
rm(vmb, evl, als, evl_union, vmb2); gc()

################################################################################
# reboot

source("scripts/knihovnik.R")

# nacist subsety vrstev
vmb <- st_read("data/processing/vmb_evl.gpkg")
evl <- st_read("data/processing/evl_als.gpkg")
evl_union <- st_read("data/processing/evl_union.gpkg")

# vypocet plochy segmentu
vmb$area <- st_area(vmb)

# Prirazeni SITECODE (z EVL) jednotlivym polygonum VMB
vmb_joined <- st_join(vmb, evl_union[, c("SITECODE", "geom")], join = st_intersects)

# Zkontrolovat vysledek
table(is.na(vmb_joined$SITECODE)) # mely by byt pouze FALSE

################################################################################
# FSB
# pokryv EVL zajmovymi skupinami FSB

fsb_target <- c("T", "M", "R", "A")

fsb_summary <- vmb_joined %>%
  mutate(fsb_in = FSB %in% fsb_target) %>%
  group_by(SITECODE) %>%
  summarise(
    total_area = sum(area, na.rm = TRUE), # celkova plocha, pro kterou mame data (na zacatky byly z VMB vylouceny polygony s atributem -1)
    fsb_area = sum(area[fsb_in], na.rm = TRUE), # plocha, kterou v ramci EVL zabiraji zajmove FSB
    fsb_ratio = fsb_area / total_area # podil celkove plochy EVL, kterou zabiraji zajmove FSB
  ) %>%
  arrange(desc(fsb_ratio))

sitecodes_fsb <- fsb_summary$SITECODE

st_write(fsb_summary, "data/results/fsb.shp")

################################################################################
# datum
# prumerny rok kdy doslo k zmene informace v danem EVL, min a max 

vmb_joined$year <- as.numeric(format(as.Date(vmb_joined$DATUM), "%Y"))

datum_summary <- vmb_joined %>%
  group_by(SITECODE) %>%
  summarise(avg_year = mean(year, na.rm = TRUE),
            newest = max(year, na.rm = T),
            oldest = min(year, na.rm = T)) %>%
  arrange(desc(avg_year))

sitecodes_datum <- datum_summary$SITECODE

st_write(datum_summary, "data/results/datum.shp")

################################################################################
################################################################################

# Nejprve vytvoř logický sloupec, které záznamy patří do zájmových FSB skupin
fsb_target <- c("T", "M", "R", "A")

vmb_joined <- vmb_joined %>%
  mutate(
    year = as.numeric(format(as.Date(DATUM), "%Y")),
    fsb_in = FSB %in% fsb_target
  )

# Shrnutí stáří dat pro všechny segmenty a zároveň jen pro zájmové FSB
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

################################################################################
################################################################################
################################################################################

fsb_summary
datum_summary

# skombinovani vysledku
summary_combined <- evl_union %>%
  select(SITECODE, NAZEV) %>%
  left_join(st_drop_geometry(fsb_summary), by = "SITECODE") %>%
  left_join(st_drop_geometry(datum_summary), by = "SITECODE")

st_write(summary_combined, "data/out/EVL_statsum.gpkg")


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
