####################################################################################
####### Object:  Manual edition of the map            
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/06/12                                        
####################################################################################

options(stringsAsFactors=FALSE)
library(Hmisc)
library(sp)
library(rgdal)
library(raster)
library(plyr)
library(foreign)
library(rgeos)

####################################################################################
#######          MERGE TILES AND FINALIZE
####################################################################################
setwd("/media/dannunzio/lecrabe/bolivia_comunidades_s2/anmi_results/filter_morphology/")

##########################################################################################
#### Extract the loss mask
system(sprintf("gdal_calc.py -A %s --outfile=%s --calc=\"%s\"",
               "chdt_closed_mask_ecoregion_pct_20170324.tif",
               "chdt_closed_mask_ecoregion_pct_20170512_lossmask.tif",
               "(A==1)+(A==5)"
))


####### Polygonize the clump results
system(sprintf("gdal_polygonize.py -mask %s -f \"ESRI Shapefile\" %s %s",
               "chdt_closed_mask_ecoregion_pct_20170512_lossmask.tif",
               "chdt_closed_mask_ecoregion_pct_20170324.tif",
               "../../results_vector_format/chdt_closed_mask_ecoregion_pct_20170324.shp"
))


####### Read the shapefile and compute areas
shp <- readOGR("../../results_vector_format/chdt_closed_mask_ecoregion_pct_20170324.shp","chdt_closed_mask_ecoregion_pct_20170324")
shp@data$polyID <- row(shp@data)[,1]
shp@data$area   <- gArea(shp,byid=T)
summary(shp@data$area)

shp@data <- arrange(shp@data,polyID)
write.dbf(shp@data,"../../results_vector_format/chdt_closed_mask_ecoregion_pct_20170324.dbf")

####### Plot the cumulated area  as a function of polygon area
df <- arrange(shp@data,area)
df$cumarea <- cumsum(df$area)
plot(df$area/10000,df$cumarea/sum(df$area),xlab="Areas of polygons (ha)",ylab="Cumulated area (% of total)")

####### See the distribution of the polygons
plot(density(log(df$area)))

s <- sapply(c(0.1,0.5,1,2,5,10,20,50),function(x){nrow(df[df$area >x*10000,])})
a <- sapply(c(0.1,0.5,1,2,5,10,20,50),function(x){sum(df[df$area >x*10000,]$area)/sum(df$area)*100})
names(a) <- names(s) <- c(0.1,0.5,1,2,5,10,20,50)

###### Visual and manual edition of the big polygons (taken > 5ha)
###### 53 polygons in the map, only 16 belong to the ANMI, 7 were modified

setwd("/media/dannunzio/lecrabe/bolivia_comunidades_s2/results_vector_format/")

##########################################################################################
#### Rasterize the edited polygons
system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               "poly_loss_gt_5ha.shp",
               "../anmi_results/filter_morphology/chdt_closed_mask_ecoregion_20170324.tif",
               "poly_loss_gt_5ha_edited.tif",
               "DN"
               ))

##########################################################################################
#### Merge into a final map
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               "../anmi_results/filter_morphology/chdt_closed_mask_ecoregion_20170324.tif",
               "poly_loss_gt_5ha_edited.tif",
               "tmp_results_edited_20170613.tif",
               "(B==0)*A+(B>0)*B"
))

##########################################################################################
#### Compress final map
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(workdir,"tmp_results_edited_20170613.tif"),
               paste0(workdir,"results_edited_20170613.tif")
               ))
