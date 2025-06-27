
#---#---#---#---#---#---#---#---#---#---#---#---#

# data (loading and preparation)

#---#---#---#---#---#---#---#---#---#---#---#---#
# libraries
source("scripts/knihovnik.R")
knihovnik(c("terra", "dplyr", "RCzechia", "sf"))

#---#---#---#---#---#---#---#---#---#---#---#---#
# vector layer ‒ VMB
vector <- vect("data/VMB/biotop_habitat.shp")

## BIOTOP_CODES & HABIT_CODES
# update "xxx (%)" format within BIOTOP_SEZ and HABIT_SEZ to BIOTOP_CODES or HABIT_CODES, where only clessification codes are kept

# checks if new cols needed 
new_cols_needed <- !c("BIOTOP_CODES", "HABIT_CODES") %in% names(vector)

# create newcols
if(any(new_cols_needed)){
  new_cols <- data.frame(
    BIOTOP_CODES = as.factor(gsub(" \\(\\d+\\)", "", vector$BIOTOP_SEZ)),
    HABIT_CODES = as.factor(gsub(" \\(\\d+\\)", "", vector$HABIT_SEZ))
  )
}

# select only wanted cols from VMB layer
required_cols <- c("SEGMENT_ID", "FSB", "BIOTOP_CODES", "HABIT_CODES", "SHAPE_AREA", "DATUM")
vector <- vector[, intersect(required_cols, names(vector))]

## Relevant mapping units
# filter mozaics and non-mapped areas
what_to_filter <- c("moz.", "-")
vector <- vector[vector$FSB %in% what_to_filter,]

## Load other datasets (Natura2000 sites with habitat protection, ALS bioclimatic zone)
vmb <- vector; rm(vector); gc()
evl <- vect("data/EVL/evl_ochrana_stanoviste_kodhabitatu.gpkg")
als <- vect("data/ALS/ALS_extracted/ALS.shp")

#---#---#---#---#---#---#---#---#---#---#---#---#
# Coordinate reference system issues
source("scripts/CRS.R")

# check, if all 
check_same_crs(c(vmb, evl, als)) # must be class vector/list
# reproject layers
layers_list <- harmonize_crs(list(vmb = vmb, evl = evl, als = als)) # must be class list
# control
check_same_crs(layers_list)

# unlist reprojected layers
vmb <- layers_list[["vmb"]]
evl <- layers_list[["evl"]]
als <- layers_list[["als"]]
rm(layers_list); gc()

#---#---#---#---#---#---#---#---#---#---#---#---#
# Save results

# create /processing
if(!dir.exists("data/processing")){
  dir.create("data/processing", recursive = T)
}

# write vector layers
writeVector(vmb, "data/processing/vmb.gpkg", overwrite = T)
writeVector(evl, "data/processing/evl.gpkg", overwrite = T)
writeVector(als, "data/processing/als.gpkg", overwrite = T)
# rm(vmb, evl, als); gc()