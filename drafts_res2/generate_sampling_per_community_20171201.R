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
#######  Choose GFC threshold
####################################################################################
thresh_gfc <- 30



####################################################################################
#######  Set name of layers of interest
####################################################################################

####### MAp derived from GFC 2016 data at 70% threshold:  1 == forest, 2 == non forest, 3 == old loss, 4 == recent loss, 0 == no data
the_map <- paste0(gfc_dir,"defor_map_gfc16_th",thresh_gfc,"_utm.tif")


####### Community boundaries TIF
anmi  <- paste0(anmi_dir,"/","community_boundaries/","communities_UTM20_20170913.tif")

####### Slope
slope <- paste0(dem_dir,"clip_slope_utm_5m.tif")

####### Aspect
aspect <- paste0(dem_dir,"clip_aspect_utm_5m.tif")

####### Elevation
altitude <- paste0(dem_dir,"clip_elev_utm_5m.tif")

####### Ecoregions
ecor <- paste0(eco_dir,"anmi_ecoregion_single_parts.tif")

####### Road network
road    <- paste0(acc_dir,"roads_utm_clip.shp")
roadtif <- paste0(acc_dir,"roads_utm_clip.tif") 

####### Road network
river    <- paste0(acc_dir,"ANMI_Streams_50_Clip.shp")
river_utm<- paste0(acc_dir,"ANMI_Streams_50_Clip_utm.shp")
rivertif <- paste0(acc_dir,"ANMI_Streams_50_Clip.tif")

####################################################################################
#######  Accessibility from road shapefile (distance to road)
####################################################################################
system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               road,
               paste0(gfc_dir,"gfc_2016_aoi_loss_2011_2016_utm.tif"),
               roadtif,
               "COCLASIFVI"
))

system(sprintf("gdal_proximity.py -ot UInt16 -co COMPRESS=LZW -co BIGTIFF=YES -distunits GEO %s %s",
               roadtif,
               paste0(mod_dir,"access_gfc16.tif")
               ))


####################################################################################
#######  Previous deforestation from GFC dataset
####################################################################################
system(sprintf("gdal_proximity.py -ot UInt16 -co COMPRESS=LZW -co BIGTIFF=YES -distunits GEO %s %s",
               loss_0010 <- paste0(gfc_dir,"gfc_2016_aoi_loss_2000_2010_utm.tif"),
               paste0(mod_dir,"dist_loss_00_10_gfc16.tif")
                      ))


###################################################################################
######  Distance to river
###################################################################################
system(sprintf("ogr2ogr -t_srs EPSG:32720 %s %s",
               river_utm,
               river
               ))
system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               river_utm,
               paste0(gfc_dir,"gfc_2016_aoi_loss_2011_2016_utm.tif"),
               rivertif,
               "Order"
))

system(sprintf("gdal_proximity.py -ot UInt16 -co COMPRESS=LZW -co BIGTIFF=YES -distunits GEO %s %s",
               rivertif,
               paste0(mod_dir,"rivers_int16_gfc16.tif")
               ))


####################################################################################
#######  Classes of the map
####################################################################################
system(sprintf("oft-stat -i %s -o %s -um %s",
               the_map,
               paste0(mod_dir,"stats_map_change_gfc16",thresh_gfc,".txt"),
               the_map
               ))

stats <- read.table(paste0(mod_dir,"stats_map_change_gfc16",thresh_gfc,".txt"))[,1:2]
names(stats) <- c("code","pixel_nb")
stats <- arrange(stats,code)

stats$class <- c("forest","non_forest","loss_old","loss_new")
stats$prop  <- round(stats$pixel_nb/sum(stats$pixel_nb)*100,digits = 2)
stats

####################################################################################
#######  Sample the map
####################################################################################

######## Load the stratification
strata <- readOGR(paste0(anmi_dir,"/","community_boundaries/","communities_UTM20_20170913.shp"))

strata <- strata[strata@data$cont_treat %in% c("cont","treat"),]
dbf    <- strata@data

nb_pts  <- 1000 # number of pixels to sample in each community
scaling <- 5   # scaling factor for oversampling loss

comm_stats <- read.csv(paste0(anmi_dir,"/","zonal_gfc2016_tc_",thresh_gfc,".csv"))
names(comm_stats)

comm_stats$prop_loss           <- comm_stats$loss_pct_11_16/100
comm_stats$nb_sampled_loss_r   <- floor(comm_stats$prop_loss * nb_pts * scaling)
comm_stats$nb_sampled_forest_r <- nb_pts - comm_stats$nb_sampled_loss_r
summary(comm_stats)

community <- dbf$ID_OTB[2]

points <- data.frame(matrix(ncol = 5,nrow = 0))
names(points) <- c("x_coord","y_coord","map_code","id","community")

map_com_dir <- paste0(mod_dir,"map_communities_gfc16_",thresh_gfc,"/")
shp_com_dir <- paste0(mod_dir,"shape_communities_",thresh_gfc,"/")

dir.create(map_com_dir)
dir.create(shp_com_dir)

################ Loop through communities to extract the number of points for each submap
for(community in dbf$ID_OTB){
  print(dbf[dbf$ID_OTB == community,"int_code"])
  com_shp <- strata[dbf$ID_OTB == community,]
  com_shp_name <- paste0(mod_dir,"shape_communities_gfc16/",community,".shp")
  writeOGR(com_shp,com_shp_name,community,"ESRI Shapefile",overwrite_layer = T)
  
  com_map_name <- paste0(mod_dir,"map_communities_gfc16/",community,".tif")
  
  e <- extent(readOGR(com_shp_name))
  
  system(sprintf("gdal_translate -co COMPRESS=LZW  -projwin %s %s %s %s %s %s",
                 e@xmin,
                 e@ymax,
                 e@xmax,
                 e@ymin,
                 the_map,
                 paste0(mod_dir,"map_communities_gfc16/tmp_",community,".tif")
                 ))
  
  system(sprintf("oft-cutline.py -v %s -i %s -o %s",
                 com_shp_name,
                 paste0(mod_dir,"map_communities_gfc16/tmp_",community,".tif"),
                 com_map_name
  ))
 
  
  file.remove(paste0(mod_dir,"map_communities_gfc16/tmp_",community,".tif"))

  nb_pts_loss <- comm_stats[comm_stats$ID_OTB == community,]$nb_sampled_loss_r
  nb_pts_fore <- comm_stats[comm_stats$ID_OTB == community,]$nb_sampled_forest_r
  
  ######## Generate PLENTY of points over the AOI. 
  ######## Shoot enough points so that you can obtain the nb_veg and nb_nvg numbers
  map <- raster(com_map_name)
  plenty <- min(200*nb_pts,ncell(map))
  
  rand_sample        <- data.frame(sampleRandom(map,plenty,xy=TRUE))
  names(rand_sample) <- c("x_coord","y_coord","map_code")
  rand_sample$id     <- row(rand_sample)[,1]
  
  ######## Look at the distribution of those points 
  (table <- table(rand_sample$map_code))
  names(table)
  
  ######## Convert from Raster to Point for RECENT LOSS
  tmp_rtp <- as.data.frame(rasterToPoints(map,fun=function(rast){(rast ==4)}))
  names(tmp_rtp) <- c("x_coord","y_coord","map_code")
  tmp_rtp$id <- row(tmp_rtp)[,1]
  
  
  avail_loss <- nrow(tmp_rtp)
  nb_pts_loss <- min(nb_pts_loss,avail_loss)
  nb_pts_fore <- nb_pts - nb_pts_loss
  
  ######## Randomly sample NB_VEG points within the stable vegetated classes
  rand_veg <- rand_sample[rand_sample$map_code %in% c(1),]
  tmp_veg  <- rand_veg[rand_veg$id %in% sample(rand_veg$id,min(nb_pts_fore,nrow(rand_sample[rand_sample$map_code ==1,]))),]
  
  ######## Randomly sample NB_LOS points within the rare classes
  tmp_los <- tmp_rtp[sample(tmp_rtp$id,nb_pts_loss),]
  
  ######## Bind the 2 datasets into one
  comm_pts <- rbind(tmp_veg,tmp_los)
  comm_pts$community <- community
  
  points <- rbind(points,comm_pts)
}

write.csv(points,paste0(mod_dir,"points_loss_forest_1000_20171201.csv"),row.names=F)

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
sp_df@data$access <- extract(raster(paste0(mod_dir,"access_gfc16.tif")),sp_df@coords)
sp_df@data$prevdf <- extract(raster(paste0(mod_dir,"dist_loss_00_10_gfc16.tif")),sp_df@coords)
sp_df@data$rivers <- extract(raster(paste0(mod_dir,"rivers_int16_gfc16.tif")),sp_df@coords)
sp_df@data$elevat <- extract(raster(altitude),sp_df@coords)
sp_df@data$slope  <- extract(raster(slope),sp_df@coords)
sp_df@data$aspect <- extract(raster(aspect),sp_df@coords)
sp_df@data$ptid   <- row(sp_df@data)[,1]
#sp_df@data$patch  <- extract(raster(paste0(mod_dir,"db_patch_loss.tif")),sp_df@coords)

df <- sp_df@data

codes_ecor <- read.dbf(paste0(eco_dir,"anmi_ecoregion_single_parts.dbf"))
codes_anmi <- read.dbf(paste0(anmi_dir,"/","community_boundaries/","communities_UTM20_20170913.dbf"))

df1 <- merge(df ,codes_ecor[,c("ECOREGION","poly_id")],by.x="ecoreg",by.y="poly_id",all.x=T)
df1 <- merge(df1,codes_anmi[,c("NOMPRED","cont_treat","ID_OTB","int_code")],
             by.x="anmi",
             by.y="int_code",
             all.x=T)

df1 <- merge(df1,stats[,c("code","class")],by.x="map_code",by.y="code",all.x=T)

sp_df@data <- arrange(df1,ptid)

sp_df@data <- cbind(sp_df@data,
                    over(sp_df,readOGR(paste0(ara_dir,"ARA_2011_2014.shp")))[,c("id_hogar","id_ARA","level")]
                    )

writeOGR(sp_df,
         paste0(mod_dir,"sampling_20171201.shp"),
         layer="sampling_20171201",
         driver="ESRI Shapefile",
         overwrite_layer = T)

df <- sp_df@data

head(df)
length(unique(df$ptid))

names(df) <- c("map_code","anmi_code","ecoreg_code","xcoord","ycoord","point_id","ID_OTB_II","dist_road","dist_prevdf","dist_river","altitude",
               "slope","aspect","all_point_id","ecoreg_name","anmi_name","cont_treat","ID_OTB_I","map_class",
               c("id_hogar","id_ARA","level"))

out <- df[df$ID_OTB_II != df$ID_OTB_I,]
out <- df[is.na(df$ecoreg_name),]
write.csv(out,paste0(mod_dir,"test.csv"),row.names = F)

df1 <- df[,c("all_point_id","xcoord","ycoord","ID_OTB_I","ID_OTB_II","map_class","anmi_name","cont_treat",
             "ecoreg_name",c("id_hogar","id_ARA","level"),
             "dist_road","dist_river","dist_prevdf","altitude","slope","aspect")]

######## Check that final distribution of points by class is balanced between control and treatment
table(df1$cont_treat,df1$map_class)

######## Check that final distribution of points by class is balanced between ECOREGIONs
table(df1$anmi_name,df1$map_class)

######## LOG DISTRIBUTIONS
######## Loss as relation to previous deforestation (the further away the less likely)
hist(log(df1[df1$map_class == "loss_new",]$dist_prevdf))

######## Loss as relation to accessibility (the further away the less likely)
hist(log(df1[df1$map_class == "loss_new",]$dist_road))

summary(df1)

write.csv(df1,
          paste0(mod_dir,"sampling_pixel_dataset_20171201_th",thresh_gfc,".csv"),
          row.names = F)
head(df1)

min(table(df1$ID_OTB_I))
max(table(df1$ID_OTB_I))
