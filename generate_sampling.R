####################################################################################
####### Object:  create a model          
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/03/27                                         
####################################################################################
options(stringsAsFactors=FALSE)

packages <- function(x){
  x <- as.character(match.call()[[2]])
  if (!require(x,character.only=TRUE)){
    install.packages(pkgs=x,repos="http://cran.r-project.org")
    require(x,character.only=TRUE)}}

packages(rgdal)
packages(raster)
packages(rgeos)
packages(ggplot2)
packages(foreign)
packages(plyr)



####################################################################################
#######  Set working directory
####################################################################################
rootdir <- "/home/dannunzio/Documents/bolivia_rct/model/"
setwd(rootdir)

####################################################################################
#######  Set name of layers of interest
####################################################################################

####### Forest change map
res2 <- "chdt_closed_mask_ecoregion_pct_20170324.tif"

####### Boundaries ANMI shapefile
bound <- "border_community_utm.shp"

####### Community boundaries TIF
anmi <- "border_community_utm.tif"

####### Slope
slope <- "clip_slope_utm.tif"

####### Aspect
aspect <- "clip_aspect_utm.tif"

####### Elevation
altitude <- "clip_elev_utm.tif"

####### GFC Loss year product
gfcl <- "gfc_ly_70.tif"

####### Ecoregions
ecor <- "anmi_ecoregion_single_parts.tif"

####### Road network
road <- "CaminosSecundarios.shp"

####################################################################################
#######  Accessibility from road shapefile (distance to road)
####################################################################################
# system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
#                "roads_utm_clip.shp",
#                gfcl,
#                "roads_utm.tif",
#                "COCLASIFVI"
# ))
# 
# system(sprintf("gdal_proximity.py -ot UInt16 -co COMPRESS=LZW -co BIGTIFF=YES -distunits GEO %s %s",
#                "roads_utm.tif",
#                "tmp_access.tif"))
# 
# system(sprintf("gdal_translate -co COMPRESS=LZW  %s %s",
#                "tmp_access.tif",
#                "access_int16.tif"))
# 
# ####################################################################################
# #######  Previous deforestation from GFC dataset
# ####################################################################################
# system(sprintf("gdal_proximity.py -ot UInt16 -values %s -co COMPRESS=LZW -co BIGTIFF=YES -distunits GEO %s %s",
#                "1,2,3,4,5,6,7,8,9,10",
#                gfcl,
#                "tmp_previous.tif"))
# 
# system(sprintf("gdal_translate -co COMPRESS=LZW  %s %s",
#                "tmp_previous.tif",
#                "previous_def.tif"))
# 
# ####################################################################################
# #######  Restrict the map to the ANMI zones only
# ####################################################################################
# system(sprintf("oft-cutline.py -v %s -i %s -o %s",
#                bound,
#                res2,
#                "tmp_map_change.tif"))
# 
# e <- extent(readOGR(bound))
# 
# system(sprintf("gdal_translate -co COMPRESS=LZW  -projwin %s %s %s %s %s %s",
#                e@xmin,
#                e@ymax,
#                e@xmax,
#                e@ymin,
#                "tmp_map_change.tif",
#                "map_change.tif"))
# 
# ####################################################################################
# #######  Classes of the map
# ####################################################################################
# system(sprintf("oft-stat -i %s -o %s -um %s",
#                "map_change.tif",
#                "stats.txt",
#                "map_change.tif"))

stats <- read.table("stats.txt")[,1:2]
names(stats) <- c("code","pixel_nb")
stats <- arrange(stats,code)

stats$class <- c("close_loss","close_stable","other","other_wet","open_loss","open_stable","shrub_loss","shrub_stable")
stats$prop  <- round(stats$pixel_nb/sum(stats$pixel_nb)*100,digits = 2)
stats

####################################################################################
#######  Sample the map
####################################################################################
nb_veg <- 10000 # number of pixels to sample in the vegetated stable classes
nb_nvg <- 5000  # number of pixels to sample in the NON vegetated stable classes
nb_los <- 10000 # number of pixels to sample in the loss classes

map <- raster("map_change.tif")

######## Generate PLENTY of points over the AOI. 
######## Shoot enough points so that you can obtain the nb_veg and nb_nvg numbers
plenty <- max(4*nb_veg,15*nb_nvg)

rand_sample        <- data.frame(sampleRandom(map,plenty,xy=TRUE))
names(rand_sample) <- c("x_coord","y_coord","map_code")
rand_sample$id     <- row(rand_sample)[,1]

######## Look at the distribution of those points 
(rp <- merge(stats,
             data.frame(table(rand_sample$map_code)),
             by.x="code",
             by.y="Var1",
             all.x=T))

######## Randomly sample NB_VEG points within the stable vegetated classes
rand_veg <- rand_sample[rand_sample$map_code %in% c(2,6,8),]
tmp_veg <- rand_veg[rand_veg$id %in% sample(rand_veg$id,nb_veg),]

######## Randomly sample NB_NVG points within the stable NON-vegetated classes
rand_nvg <- rand_sample[rand_sample$map_code %in% c(3,4),]
tmp_nvg <- rand_nvg[rand_nvg$id %in% sample(rand_nvg$id,nb_nvg),]

######## Convert from Raster to Point for the rare classes (1,446,159 pixels)
tmp_rtp <- as.data.frame(rasterToPoints(map,fun=function(rast){(rast==1)|(rast==5)|(rast==7)}))
names(tmp_rtp) <- c("x_coord","y_coord","map_code")
tmp_rtp$id <- row(tmp_rtp)[,1]

######## Randomly sample NB_LOS points within the rare classes
tmp_los <- tmp_rtp[tmp_rtp$id %in% sample(tmp_rtp$id,nb_los),]

######## Bind the 3 datasets into one and convert to Spatial Points
points <- rbind(tmp_veg,tmp_los,tmp_nvg)

sp_df <- SpatialPointsDataFrame(
  coords=points[,c(1,2)],
  data=data.frame(points[,c(1,2,3)]),
  proj4string=CRS(proj4string(map))
)

names(sp_df) <- c("xcoord","ycoord","map_code")
table(sp_df@data$map_code)

####################################################################################
#######  Extract information from the other layers
####################################################################################
sp_df@data$anmi   <- extract(raster(anmi),sp_df@coords)
sp_df@data$ecoreg <- extract(raster(ecor),sp_df@coords)
sp_df@data$access <- extract(raster("access_int16.tif"),sp_df@coords)
sp_df@data$prevdf <- extract(raster("previous_def.tif"),sp_df@coords)
sp_df@data$elevat <- extract(raster(altitude),sp_df@coords)
sp_df@data$slope  <- extract(raster(slope),sp_df@coords)
sp_df@data$aspect  <- extract(raster(aspect),sp_df@coords)

sp_df@data$ptid   <- row(sp_df@data)[,1]

df <- sp_df@data

codes_ecor <- read.dbf("anmi_ecoregion_single_parts.dbf")
codes_anmi <- read.dbf("border_community_utm.dbf")

df1 <- merge(df,codes_ecor[,c("ECOREGION","poly_id")],by.x="ecoreg",by.y="poly_id",all.x=T)
df1 <- merge(df1,codes_anmi[,c("NOMPRED","cont_treat","cod_otb","code")],by.x="anmi",by.y="code",all.x=T)
df1 <- merge(df1,stats[,c("code","class")],by.x="map_code",by.y="code",all.x=T)

sp_df@data <- arrange(df1,ptid)

sp_df@data <- cbind(sp_df@data,over(sp_df,readOGR("ARA_ID_SIG.shp"))[,c(2,4,5)])
df <- sp_df@data

writeOGR(sp_df,"sampling.shp",layer="sampling",driver="ESRI Shapefile",overwrite_layer = T)

names(df) <- c("map_code","anmi_code","ecoreg_code","xcoord","ycoord","dist_road","dist_prevdf","altitude",
               "slope","aspect","point_id","ecoreg_name","anmi_name","cont_treat","cod_otb","map_class","dueno","municipio","comunidad")

df1 <- df[,c("point_id","xcoord","ycoord","map_class","anmi_name","cont_treat",
             "cod_otb","ecoreg_name","dueno","municipio","comunidad",
             "dist_road","dist_prevdf","altitude","slope","aspect")]

df1[is.na(df1$aspect),]$aspect <- 0
df1$loss <- 0
df1[grep("loss",df1$map_class),]$loss <- 1

######## Check that final distribution of points by class is balanced between control and treatment
table(df1$cont_treat,df1$loss)

######## Check that final distribution of points by class is balanced between ECOREGIONs
table(df1$ecoreg_name,df1$loss)

######## LOG DISTRIBUTIONS
######## Loss as relation to previous deforestation (the further away the less likely)
hist(log(df1[df1$loss == 1,]$dist_prevdf))

######## Loss as relation to accessibility (the further away the less likely)
hist(log(df1[df1$loss == 1,]$dist_road))

summary(df1)

write.csv(df1,"dataset.csv",row.names = F)

