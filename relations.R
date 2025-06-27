#---#---#---#---#---#---#---#---#---#---#---#---#

# Layers relations

#---#---#---#---#---#---#---#---#---#---#---#---#

# Reload data, if needed
# vmb <- vect("data/processing/vmb.gpkg")
# evl <- vect("data/processing/evl.gpkg")
# als <- vect("data/processing/als.gpkg")

#---#---#---#---#---#---#---#---#---#---#---#---#
# Spatial relation DE-9IM: T******** (intersect)

# Vyber pouze tech EVL, ktere jsou ve vztahu s ALS zonou
idx <- relate(evl, als, "T********")
evl <- evl[idx == T, ]

# Slouceni radku EVL, aggN reprezentuje pocet chranenych typu biotopu v danem EVL
# (nepotrebuju mit pro kazde EVL vic polygonu, minimalne ne pro prvni dve analyzy)
evl_union <- aggregate(evl, by = "SITECODE")

# Vyber segmentu VMB, ktere maji vztah s vybranymi EVL
idx <- relate(vmb, evl_union, "T********", pairs = TRUE) # Vytvoření indexu všech překryvů (vmb vs. evl_union)
vmb <- vmb[unique(idx[,1]), ] # Výběr všech unikátních indexů z vmb, které mají nějaký vztah z množiny T*********

#---#---#---#---#---#---#---#---#---#---#---#---#
# other manipulation

# compute exact polygon area
vmb$area <- st_area(vmb)

# Mark which polygons fall under which EVL sites
vmb_joined <- st_join(vmb, evl_union[, c("SITECODE", "geom")], join = st_intersects)
# Check results ‒ should be only FALSE
table(is.na(vmb_joined$SITECODE))

#---#---#---#---#---#---#---#---#---#---#---#---#
# Save outputs
writeVector(vmb, "data/processing/vmb_evl.gpkg", overwrite = T)
writeVector(evl, "data/processing/evl_als.gpkg", overwrite = T)
writeVector(evl_union, "data/processing/evl_union.gpkg", overwrite = T)
writeVector(vmb_joined, "data/processing/vmb_joined.gpkg", overwrite = T)
# rm(vmb, evl, als, evl_union, vmb_joined); gc()