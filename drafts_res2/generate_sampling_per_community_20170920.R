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
anmi  <- paste0(anmi_dir,"/","community_boundaries/","communities_UTM20_20170913.tif")

####### Slope
slope <- paste0(dem_dir,"clip_slope_utm_5m.tif")

####### Aspect
aspect <- paste0(dem_dir,"clip_aspect_utm_5m.tif")

####### Elevation
altitude <- paste0(dem_dir,"clip_elev_utm_5m.tif")

####### GFC Loss year product
gfcl <- paste0(gfc_dir,"gfc_ly_70.tif")

####### Ecoregions
ecor <- paste0(eco_dir,"anmi_ecoregion_single_parts.tif")

####### Road network
road    <- paste0(acc_dir,"roads_utm_clip.shp")
roadtif <- paste0(acc_dir,"roads_utm_clip.tif") 

####### Road network
river    <- paste0(acc_dir,"ANMI_Streams_50_Clip.shp")
rivertif <- paste0(acc_dir,"ANMI_Streams_50_Clip.tif")

####################################################################################
#######  Accessibility from road shapefile (distance to road)
####################################################################################
system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               road,
               gfcl,
               roadtif,
               "COCLASIFVI"
))

system(sprintf("gdal_proximity.py -ot UInt16 -co COMPRESS=LZW -co BIGTIFF=YES -distunits GEO %s %s",
               roadtif,
               paste0(mod_dir,"access.tif")
               ))


####################################################################################
#######  Previous deforestation from GFC dataset
####################################################################################
system(sprintf("gdal_proximity.py -ot UInt16 -values %s -co COMPRESS=LZW -co BIGTIFF=YES -distunits GEO %s %s",
               "1,2,3,4,5,6,7,8,9,10",
               gfcl,
               paste0(mod_dir,"previous.tif")
                      ))


###################################################################################
######  Distance to river
###################################################################################

system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               river,
               gfcl,
               rivertif,
               "Order"
))

system(sprintf("gdal_proximity.py -ot UInt16 -co COMPRESS=LZW -co BIGTIFF=YES -distunits GEO %s %s",
               rivertif,
               paste0(mod_dir,"rivers_int16.tif")
               ))

####################################################################################
#######  Restrict the map to the ANMI zones only
####################################################################################
system(sprintf("oft-cutline.py -v %s -i %s -o %s",
               bound,
               res2,
               paste0(mod_dir,"tmp_map_change.tif")
               ))

e <- extent(readOGR(bound))

system(sprintf("gdal_translate -co COMPRESS=LZW  -projwin %s %s %s %s %s %s",
               e@xmin,
               e@ymax,
               e@xmax,
               e@ymin,
               paste0(mod_dir,"tmp_map_change.tif"),
               paste0(mod_dir,"map_change.tif")
               ))

####################################################################################
#######  Classes of the map
####################################################################################
system(sprintf("oft-stat -i %s -o %s -um %s",
               paste0(mod_dir,"map_change.tif"),
               paste0(mod_dir,"stats_map_change.txt"),
               paste0(mod_dir,"map_change.tif")
               ))

stats <- read.table(paste0(mod_dir,"stats_map_change.txt"))[,1:2]
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

comm_stats <- read.csv(paste0(rootdir,"stats_db_ecoregions_20170920.csv"))

comm_stats$prop_loss           <- (comm_stats$loss_ha_res2+comm_stats$openf_loss_ha_res2)/(comm_stats$loss_ha_res2+comm_stats$openf_loss_ha_res2+comm_stats$forest_ha_res2+comm_stats$openf_stable_ha_res2)
comm_stats$nb_sampled_loss_r   <- floor(comm_stats$prop_loss * nb_pts * scaling)
comm_stats$nb_sampled_forest_r <- nb_pts - comm_stats$nb_sampled_loss_r

community <- dbf$ID_OTB[2]

points <- data.frame(matrix(ncol = 5,nrow = 0))
names(points) <- c("x_coord","y_coord","map_code","id","community")

dir.create(paste0(mod_dir,"map_communities/"))
dir.create(paste0(mod_dir,"shape_communities/"))

################ Loop through communities to extract the number of points for each submap
for(community in dbf$ID_OTB[1:128]){
  print(dbf[dbf$ID_OTB == community,"int_code"])
  com_shp <- strata[dbf$ID_OTB == community,]
  com_shp_name <- paste0(mod_dir,"shape_communities/",community,".shp")
  writeOGR(com_shp,com_shp_name,community,"ESRI Shapefile",overwrite_layer = T)
  
  com_map_name <- paste0(mod_dir,"map_communities/",community,".tif")
  
  e <- extent(readOGR(com_shp_name))
  
  system(sprintf("gdal_translate -co COMPRESS=LZW  -projwin %s %s %s %s %s %s",
                 e@xmin,
                 e@ymax,
                 e@xmax,
                 e@ymin,
                 res2,
                 paste0(mod_dir,"map_communities/tmp_",community,".tif")
                 ))
  
  system(sprintf("oft-cutline.py -v %s -i %s -o %s",
                 com_shp_name,
                 paste0(mod_dir,"map_communities/tmp_",community,".tif"),
                 com_map_name
  ))
 
  
  file.remove(paste0(mod_dir,"map_communities/tmp_",community,".tif"))

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
  
  ######## Convert from Raster to Point for the rare classes (1,446,159 pixels)
  tmp_rtp <- as.data.frame(rasterToPoints(map,fun=function(rast){(rast==1)|(rast==5)}))
  names(tmp_rtp) <- c("x_coord","y_coord","map_code")
  tmp_rtp$id <- row(tmp_rtp)[,1]
  
  
  avail_loss <- nrow(tmp_rtp)
  nb_pts_loss <- min(nb_pts_loss,avail_loss)
  nb_pts_fore <- nb_pts - nb_pts_loss
  
  ######## Randomly sample NB_VEG points within the stable vegetated classes
  rand_veg <- rand_sample[rand_sample$map_code %in% c(2,6),]
  tmp_veg  <- rand_veg[rand_veg$id %in% sample(rand_veg$id,nb_pts_fore),]
  
  ######## Randomly sample NB_LOS points within the rare classes
  tmp_los <- tmp_rtp[sample(tmp_rtp$id,nb_pts_loss),]
  
  ######## Bind the 2 datasets into one
  comm_pts <- rbind(tmp_veg,tmp_los)
  comm_pts$community <- community
  
  points <- rbind(points,comm_pts)
}

write.csv(points,paste0(mod_dir,"points_loss_forest_1000_20170920.csv"),row.names=F)

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
sp_df@data$access <- extract(raster(paste0(mod_dir,"access.tif")),sp_df@coords)
sp_df@data$prevdf <- extract(raster(paste0(mod_dir,"previous.tif")),sp_df@coords)
sp_df@data$rivers <- extract(raster(paste0(mod_dir,"rivers_int16.tif")),sp_df@coords)
sp_df@data$elevat <- extract(raster(altitude),sp_df@coords)
sp_df@data$slope  <- extract(raster(slope),sp_df@coords)
sp_df@data$aspect <- extract(raster(aspect),sp_df@coords)
sp_df@data$ptid   <- row(sp_df@data)[,1]
sp_df@data$patch  <- extract(raster(paste0(mod_dir,"db_patch_loss.tif")),sp_df@coords)

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
         paste0(mod_dir,"sampling_20170920.shp"),
         layer="sampling_20170920",
         driver="ESRI Shapefile",
         overwrite_layer = T)

df <- sp_df@data

head(df)
length(unique(df$ptid))

names(df) <- c("map_code","anmi_code","ecoreg_code","xcoord","ycoord","point_id","ID_OTB_II","dist_road","dist_prevdf","dist_river","altitude",
               "slope","aspect","all_point_id","loss_patch_id","ecoreg_name","anmi_name","cont_treat","ID_OTB_I","map_class",
               c("id_hogar","id_ARA","level"))

out <- df[df$ID_OTB_II != df$ID_OTB_I,]
out <- df[is.na(df$ecoreg_name),]
write.csv(out,paste0(mod_dir,"test.csv"),row.names = F)

df1 <- df[,c("all_point_id","xcoord","ycoord","ID_OTB_I","ID_OTB_II","loss_patch_id","map_class","anmi_name","cont_treat",
             "ecoreg_name",c("id_hogar","id_ARA","level"),
             "dist_road","dist_river","dist_prevdf","altitude","slope","aspect")]

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

write.csv(df1,
          paste0(mod_dir,"dataset_20170920.csv"),
          row.names = F)
head(df1)

min(table(df1$ID_OTB_I))
max(table(df1$ID_OTB_I))
