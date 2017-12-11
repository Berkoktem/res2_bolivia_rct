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

####################################################################################
#######  Set name of layers of interest
####################################################################################

####### Forest change map
res2 <- paste0(workdir,"results_edited_20170613.tif")


####### Boundaries ANMI shapefile
bound <- paste0(anmi_dir,"/","community_boundaries/","communities_UTM20_20170913.shp")

####### Community boundaries TIF
anmi <- paste0(anmi_dir,"/","community_boundaries/","communities_UTM20_20170913.tif")

# system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
#                bound,
#                res2,
#                anmi,
#                "int_code"
# ))

####### Slope
slope <- paste0(dem_dir,"clip_slope_utm.tif")

####### Aspect
aspect <- paste0(dem_dir,"clip_aspect_utm.tif")

####### Elevation
altitude <- paste0(dem_dir,"clip_elev_utm.tif")

####### GFC Loss year product
gfcl <- paste0(gfc_dir,"gfc_ly_70.tif")

####### Ecoregions
ecor <- paste0(eco_dir,"anmi_ecoregion_single_parts.tif")

####### Road network
road <- paste0(acc_dir,"roads_utm_clip.shp")

####### Road network
river <- paste0(acc_dir,"ANMI_Streams_50_Clip.shp")

####################################################################################
#######  Accessibility from road shapefile (distance to road)
####################################################################################
system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               road,
               gfcl,
               "roads_utm.tif",
               "COCLASIFVI"
))

system(sprintf("gdal_proximity.py -ot UInt16 -co COMPRESS=LZW -co BIGTIFF=YES -distunits GEO %s %s",
               "roads_utm.tif",
               "tmp_access.tif"))

system(sprintf("gdal_translate -co COMPRESS=LZW  %s %s",
               "tmp_access.tif",
               "access_int16.tif"))

####################################################################################
#######  Previous deforestation from GFC dataset
####################################################################################
system(sprintf("gdal_proximity.py -ot UInt16 -values %s -co COMPRESS=LZW -co BIGTIFF=YES -distunits GEO %s %s",
               "1,2,3,4,5,6,7,8,9,10",
               gfcl,
               "tmp_previous.tif"))

system(sprintf("gdal_translate -co COMPRESS=LZW  %s %s",
               "tmp_previous.tif",
               "previous_def.tif"))


###################################################################################
######  Distance to river
###################################################################################
# rivers_dbf <- read.dbf("ANMI_Streams_50_Clip.dbf")
# summary(rivers_dbf)
# system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
#                "ANMI_Streams_50_Clip.shp",
#                gfcl,
#                "rivers_utm.tif",
#                "Order"
# ))
# 
# system(sprintf("gdal_proximity.py -ot UInt16 -co COMPRESS=LZW -co BIGTIFF=YES -distunits GEO %s %s",
#                "rivers_utm.tif",
#                "tmp_access.tif"))
# 
# system(sprintf("gdal_translate -co COMPRESS=LZW  %s %s",
#                "tmp_access.tif",
#                "rivers_int16.tif"))

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

######## Load the stratification
strata <- readOGR(bound)

strata <- strata[strata@data$cont_treat %in% c("cont","treat"),]
dbf    <- strata@data

nb_pts  <- 1000 # number of pixels to sample in each community
scaling <- 20   # scaling factor for oversampling loss

comm_stats <- read.csv("stats_defor_community_20170720.csv")

comm_stats$prop_loss <- (comm_stats$loss_ha_res2+comm_stats$openf_loss_ha_res2)/(comm_stats$loss_ha_res2+comm_stats$openf_loss_ha_res2+comm_stats$forest_ha_res2+comm_stats$openf_stable_ha_res2)
comm_stats$nb_sampled_loss_r   <- floor(comm_stats$prop_loss * nb_pts * scaling)
comm_stats$nb_sampled_forest_r <- nb_pts - comm_stats$nb_sampled_loss_r

community <- dbf$cod_otb[2]

points <- data.frame(matrix(ncol = 5,nrow = 0))
names(points) <- c("x_coord","y_coord","map_code","id","community")

community <- "MPAM"

for(community in dbf$cod_otb[1:128]){
  
  com_shp <- strata[dbf$cod_otb == community,]
  com_shp_name <- paste0("shape_communities/",community,".shp")
  writeOGR(com_shp,com_shp_name,community,"ESRI Shapefile",overwrite_layer = T)
  
  com_map_name <- paste0("map_communities/",community,".tif")
  
  system(sprintf("oft-cutline.py -v %s -i %s -o %s",
                 com_shp_name,
                 res2,
                 paste0("map_communities/tmp_",community,".tif")
  ))
  
  e <- extent(readOGR(com_shp_name))
  
  system(sprintf("gdal_translate -co COMPRESS=LZW  -projwin %s %s %s %s %s %s",
                 e@xmin,
                 e@ymax,
                 e@xmax,
                 e@ymin,
                 paste0("map_communities/tmp_",community,".tif"),
                 com_map_name))
  
  file.remove(paste0("map_communities/tmp_",community,".tif"))

  nb_pts_loss <- comm_stats[comm_stats$cod_otb == community,]$nb_sampled_loss_r
  nb_pts_fore <- comm_stats[comm_stats$cod_otb == community,]$nb_sampled_forest_r
  
  ######## Generate PLENTY of points over the AOI. 
  ######## Shoot enough points so that you can obtain the nb_veg and nb_nvg numbers
  plenty <- max(200*nb_pts)
  map <- raster(com_map_name)
  
  rand_sample        <- data.frame(sampleRandom(map,plenty,xy=TRUE))
  names(rand_sample) <- c("x_coord","y_coord","map_code")
  rand_sample$id     <- row(rand_sample)[,1]
  
  ######## Look at the distribution of those points 
  table(rand_sample$map_code)
               
  ######## Randomly sample NB_VEG points within the stable vegetated classes
  rand_veg <- rand_sample[rand_sample$map_code %in% c(2,6),]
  tmp_veg  <- rand_veg[rand_veg$id %in% sample(rand_veg$id,nb_pts_fore),]
  #tmp_veg  <- rand_veg[rand_veg$id %in% sample(rand_veg$id,907),]

  ######## Convert from Raster to Point for the rare classes (1,446,159 pixels)
  tmp_rtp <- as.data.frame(rasterToPoints(map,fun=function(rast){(rast==1)|(rast==5)}))
  names(tmp_rtp) <- c("x_coord","y_coord","map_code")
  tmp_rtp$id <- row(tmp_rtp)[,1]
  
  ######## Randomly sample NB_LOS points within the rare classes
  tmp_los <- tmp_rtp[tmp_rtp$id %in% sample(tmp_rtp$id,nb_pts_loss),]
  
  ######## Bind the 2 datasets into one
  comm_pts <- rbind(tmp_veg,tmp_los)
  comm_pts$community <- community
  
  points <- rbind(points,comm_pts)
}

write.csv(points,"points_loss_forest_1000_20170720.csv",row.names=F)

dbf$cod_otb[!(dbf$cod_otb %in% unique(points$community))]

sp_df <- SpatialPointsDataFrame(
  coords=points[,c(1,2)],
  data=data.frame(points),
  proj4string=CRS(proj4string(map))
)

names(sp_df) <- c("xcoord","ycoord","map_code","point_id","community")
table(sp_df@data$map_code)

####################################################################################
#######  Extract information from the other layers
####################################################################################
sp_df@data$anmi   <- extract(raster(anmi),sp_df@coords)
sp_df@data$ecoreg <- extract(raster(ecor),sp_df@coords)
sp_df@data$access <- extract(raster("access_int16.tif"),sp_df@coords)
sp_df@data$prevdf <- extract(raster("previous_def.tif"),sp_df@coords)
sp_df@data$rivers <- extract(raster("rivers_int16.tif"),sp_df@coords)
sp_df@data$elevat <- extract(raster(altitude),sp_df@coords)
sp_df@data$slope  <- extract(raster(slope),sp_df@coords)
sp_df@data$aspect <- extract(raster(aspect),sp_df@coords)
sp_df@data$ptid   <- row(sp_df@data)[,1]
sp_df@data$patch  <- extract(raster("db_patch_loss.tif"),sp_df@coords)

df <- sp_df@data

codes_ecor <- read.dbf("anmi_ecoregion_single_parts.dbf")
codes_anmi <- read.dbf("border_community_utm.dbf")

df1 <- merge(df,codes_ecor[,c("ECOREGION","poly_id")],by.x="ecoreg",by.y="poly_id",all.x=T)
df1 <- merge(df1,codes_anmi[,c("NOMPRED","cont_treat","cod_otb","code")],by.x="anmi",by.y="code",all.x=T)
df1 <- merge(df1,stats[,c("code","class")],by.x="map_code",by.y="code",all.x=T)

sp_df@data <- arrange(df1,ptid)

sp_df@data <- cbind(sp_df@data,over(sp_df,readOGR("ARA_ID_SIG.shp"))[,c(2,4,5)])
df <- sp_df@data

writeOGR(sp_df,"sampling_20170720.shp",layer="sampling_20170720",driver="ESRI Shapefile",overwrite_layer = T)
head(df)
names(df) <- c("map_code","anmi_code","ecoreg_code","xcoord","ycoord","point_id","community","dist_road","dist_prevdf","dist_river","altitude",
               "slope","aspect","all_point_id","loss_patch_id","ecoreg_name","anmi_name","cont_treat","cod_otb","map_class","dueno","municipio","comunidad")

df1 <- df[,c("all_point_id","xcoord","ycoord","community","loss_patch_id","map_class","anmi_name","cont_treat",
             "cod_otb","ecoreg_name","dueno","municipio","comunidad",
             "dist_road","dist_river","dist_prevdf","altitude","slope","aspect")]

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

write.csv(df1,"dataset_20170720.csv",row.names = F)
head(df1)
table(df1$cod_otb)
