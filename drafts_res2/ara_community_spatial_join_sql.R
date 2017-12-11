####################################################################################################
####################################################################################################
## SQL OGR2OGR
## Contact remi.dannunzio@fao.org
## 2017/09/13 -- BOlivia
####################################################################################################
####################################################################################################
options(stringsAsFactors=FALSE)

library(Hmisc)
library(sp)
library(rgdal)
library(raster)
library(plyr)
library(foreign)

#######################################################################
##############################     SETUP YOUR DATA 
#######################################################################

## Set your working directory
setwd("/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/bolivia/gis_bolivia_rct/sql_joins/")

## Read the datafiles
# system(sprintf("ogr2ogr -sql \"SELECT * FROM %s WHERE %s=%s\" %s %s",
#                "communities_UTM20_20170913",
#                "ID_OTB",
#                "'VAPO'",
#                "output.shp",
#                "communities_UTM20_20170913.shp"
#                ))

shp1 <- readOGR("ARA_2011_2014.shp","ARA_2011_2014")
shp2 <- readOGR("communities_UTM20_20170913.shp","communities_UTM20_20170913")

names(shp1)
names(shp2)

shp2@data$ID_OTB <- as.factor(shp2@data$ID_OTB)
shp1$id_OTB_LOC  <- aggregate(x  = shp2[,"ID_OTB"], 
                              by = shp1, 
                              areaWeighted=T
                              )$ID_OTB

writeOGR(obj = shp1,dsn = "output.shp",layer = "output","ESRI Shapefile",overwrite_layer = T)

table(shp1$id_OTB_LOC,shp1$id_OTB)
