####################################################################################################
####################################################################################################
## DOWNLOAD AND PREPARE GFC DATA 2016
## Contact remi.dannunzio@fao.org 
## 2017/11/28
####################################################################################################
####################################################################################################

options(stringsAsFactors = FALSE)

### Load necessary packages
library(gfcanalysis)
library(rgeos)
library(ggplot2)
library(rgdal)
library(raster)


## Select the folder where your GFC data archives are stored
gfc_folder    <-  "/media/dannunzio/lecrabe/gis_data/gfc_hansen_umd/gfc_2016/"


#######################################################################
############  PART I: Check GFC data availability - download if needed
#######################################################################
### Make vector layer of tiles that cover the country

####### Boundaries ANMI shapefile
aoi <- readOGR(paste0(anmi_dir,"/","community_boundaries/","communities_UTM20_20170913.shp"))
aoi <- spTransform(aoi,CRS("+init=epsg:4326"))
writeOGR(aoi,
         paste0(anmi_dir,"/","community_boundaries/","communities_geo_20171129.shp"),
         "communities_geo_20171129",
         "ESRI Shapefile",
         overwrite_layer = T)

tiles           <- calc_gfc_tiles(aoi)

proj4string(tiles) <- proj4string(aoi)
tiles <- tiles[aoi,]

### Find the suffix of the associated GFC data for each tile
tmp         <- data.frame(1:length(tiles),rep("nd",length(tiles)))
names(tmp)  <- c("tile_id","gfc_suffix")

for (n in 1:length(tiles)) {
  gfc_tile <- tiles[n, ]
  min_x <- bbox(gfc_tile)[1, 1]
  max_y <- bbox(gfc_tile)[2, 2]
  if (min_x < 0) {min_x <- paste0(sprintf("%03i", abs(min_x)), "W")}
  else {min_x <- paste0(sprintf("%03i", min_x), "E")}
  if (max_y < 0) {max_y <- paste0(sprintf("%02i", abs(max_y)), "S")}
  else {max_y <- paste0(sprintf("%02i", max_y), "N")}
  tmp[n,2] <- paste0("_", max_y, "_", min_x, ".tif")
}

### Store the information into a SpatialPolygonDF
df_tiles <- SpatialPolygonsDataFrame(tiles,tmp,match.ID = F)
rm(tmp)

### Display the tiles and area of interest to check
plot(df_tiles)
plot(aoi,add=T)


download_gfc_2016 <- function (tiles, output_folder, images = c("treecover2000", "loss", 
                                                                "gain", "lossyear", "datamask")) 
{ 
  base <- "https://storage.googleapis.com/earthenginepartners-hansen/GFC-2016-v1.4/"
  
  stopifnot(all(images %in% c("treecover2000", "loss", "gain", 
                              "lossyear", "datamask", "first", "last")))
  if (!file_test("-d", output_folder)) {
    stop("output_folder does not exist")
  }
  message(paste(length(tiles), "tiles to download/check."))
  successes <- 0
  failures <- 0
  skips <- 0
  for (n in 1:length(tiles)) {
    gfc_tile <- tiles[n, ]
    min_x <- bbox(gfc_tile)[1, 1]
    max_y <- bbox(gfc_tile)[2, 2]
    if (min_x < 0) {
      min_x <- paste0(sprintf("%03i", abs(min_x)), "W")
    }
    else {
      min_x <- paste0(sprintf("%03i", min_x), "E")
    }
    if (max_y < 0) {
      max_y <- paste0(sprintf("%02i", abs(max_y)), "S")
    }
    else {
      max_y <- paste0(sprintf("%02i", max_y), "N")
    }
    file_root   <- "Hansen_GFC-2016-v1.4_"
    file_suffix <- paste0("_", max_y, "_", min_x, ".tif")
    filenames   <- paste0(file_root, images, file_suffix)
    tile_urls   <- paste0(paste0(base, filenames))
    local_paths <- file.path(output_folder, filenames)
    for (i in 1:length(filenames)) {
      tile_url <- tile_urls[i]
      local_path <- local_paths[i]
      if (file.exists(local_path)) {
        print(paste0("skipping ",local_path))
        skips <- skips + 1
        next
      }
      # system(sprintf("wget %s -O %s",
      #                tile_url,
      #                local_path))
      download.file(tile_url,local_path,method="auto")
      if (file.exists(local_path)) {
        successes <- successes + 1
      }
      else {
        failures <- failures + 1
      }
    }
  }
  message(paste(successes, "file(s) succeeded,", skips, "file(s) skipped,", 
                failures, "file(s) failed."))
}

### Check if tiles are available and download otherwise : download can take some time
beginCluster()
download_gfc_2016(tiles,
                  gfc_folder,
                  images = c("treecover2000","lossyear","gain","datamask"))
endCluster()

types <- c("treecover2000","lossyear","gain","datamask")
prefix <- "Hansen_GFC-2016-v1.4_"
tile <- "10S_070W"
type <- types[1]

for(type in types){
  print(type)
  
  system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -co COMPRESS=LZW %s %s",
                 aoi@bbox[1,1],
                 aoi@bbox[2,2],
                 aoi@bbox[1,2],
                 aoi@bbox[2,1],
                 paste0(gfc_folder,prefix,type,"_",tile,".tif"),
                 paste0(gfc_dir,"gfc_2016_bb_",type,".tif")
  ))
}
