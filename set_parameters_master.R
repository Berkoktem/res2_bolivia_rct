####################################################################################
####### Object:  Prepare names of all intermediate products                 
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/10/31                                          
####################################################################################

####################################################################################
#######          PACKAGES
####################################################################################
options(stringsAsFactors=FALSE)

packages <- function(x){
  x <- as.character(match.call()[[2]])
  if (!require(x,character.only=TRUE)){
    install.packages(pkgs=x,repos="http://cran.r-project.org")
    require(x,character.only=TRUE)
  }
}

packages(rgdal)
packages(raster)
packages(rgeos)

packages(ggplot2)
packages(xtable)
packages(foreign)
packages(dismo)
packages(stringr)
packages(plyr)

packages(snow)

packages(leaflet)
packages(RColorBrewer)
packages(DT)

packages(RStoolbox)
packages(e1071)
packages(randomForest)

####################################################################################
#######          GLOBAL ENVIRONMENT VARIABLES
####################################################################################

#rootdir <- "/media/dannunzio/lecrabe/bolivia_comunidades_s2/"
rootdir <- "d:/bolivia_comunidades_s2/"

select    <- read.csv(paste0(rootdir,"selection_s2_RE.csv"))

all_re_dir    <- paste0(rootdir,"rapideye_2010_2011/RE_2011/")
all_s2_dir    <- paste0(rootdir,"sentinel_2016/s2_tiled_re_gee/")

result_dir<- paste0(rootdir,"results/")
anmi_dir  <- paste0(rootdir,"anmi_results/")
gfc_dir   <- paste0(rootdir,"gfc_bolivia/")
eco_dir   <- paste0(rootdir,"ecoregion_bolivia_rct/")
ara_dir   <- paste0(rootdir,"ara_delimitations/")
dem_dir   <- paste0(rootdir,"dem_bolivia_rct/")
acc_dir   <- paste0(rootdir,"access_bolivia/")
mod_dir   <- paste0(rootdir,"model/")

#workdir   <- paste0(anmi_dir,"filter_morphology/")
workdir   <- paste0(rootdir,"results_vector_format/")

zonal_dir <- paste0(rootdir,"zonal_stats/")

pbs_input <- paste0(rootdir,"pbs_bolivia_rct/pbs_bolivia_rct_utm.tif")

dem_input <- paste0(rootdir,"dem_bolivia_rct/srtm_elev_bolivia_rct.tif")
slp_input <- paste0(rootdir,"dem_bolivia_rct/srtm_slope_bolivia_rct.tif")
asp_input <- paste0(rootdir,"dem_bolivia_rct/srtm_aspect_bolivia_rct.tif")


####################################################################################
#######          PARAMETERS
####################################################################################
spacing_km  <- 500  # UTM in meters, Point spacing in grid for unsupervised classification
th_shd      <- 30   # in degrees (higher than threshold and dark is mountain shadow)
th_wat      <- 15   # in degrees (lower than threshold is water)
rate        <- 100  # Define the sampling rate (how many objects per cluster)
minsg_size  <- 100  # in numbers of pixels

thresh_imad <- 10000 # acceptable threshold for no_change mask from IMAD
thresh_gfc  <- 70    # tree cover threshold from GFC to define forests

size_morpho  <- 2   # morphological filter size to apply at end of classification (closing)

pixel_size <- 5
##### Band combination gets harmonized through the hardcoded imad process (TO BE FIXED FOR MORE GENERIC SOLUTIONS)
GRN <- "#2" # Band number of the imagery for the green (Rapideye 2 Sentinel 2)
RED <- "#3" # Band number of the imagery for the red   (Rapideye 3 Sentinel 3)
NIR <- "#4" # Band number of the imagery for the near infrared (Rapideye 5 Sentinel 4)

pbs_wat_class <- 4  # class for water
pbs_shd_class <- 40 # class for shadows
