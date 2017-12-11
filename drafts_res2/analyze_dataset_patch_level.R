####################################################################################
####### Object:  Compute all necessary variables at loss patch level         
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/06/15                                         
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
setwd("/home/dannunzio/Documents/bolivia_rct/model/")
setwd(rootdir)

####################################################################################
#######  Set name of layers of interest
####################################################################################

####### Forest change map
res2 <- "results_edited_20170613_pct.tif"

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

####### Road network
river <- "ANMI_Streams_50_Clip.shp"

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

###################################################################################
######  Distance to river (rasterize @ 30m using GFCL as basis)
###################################################################################
# rivers_dbf <- read.dbf("ANMI_Streams_50_Clip.dbf")
# summary(rivers_dbf)
# system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
#                "ANMI_Streams_50_Clip.shp",
#                gfcl,
#                "rivers_utm.tif",
#                "Order"
# ))

###################################################################################
######  Select only major rivers (order 6 and above)
###################################################################################
system(sprintf("gdal_calc.py -A %s --outfile=%s --co COMPRESS=LZW --calc=\"%s\"",
               "rivers_utm.tif",
               "rivers_utm_order_gt_5.tif",
               "(A>5)"
))

system(sprintf("gdal_proximity.py -ot UInt16 -co COMPRESS=LZW -co BIGTIFF=YES -distunits GEO %s %s",
               "rivers_utm_order_gt_5.tif",
               "tmp_access.tif"))

system(sprintf("gdal_translate -co COMPRESS=LZW  %s %s",
               "tmp_access.tif",
               "rivers_int16.tif"))

# ####################################################################################
# #######  Restrict the map to the ANMI zones only
# ####################################################################################
system(sprintf("oft-cutline.py -v %s -i %s -o %s",
               bound,
               res2,
               "tmp_map_change.tif"))

e <- extent(readOGR(bound))

system(sprintf("gdal_translate -co COMPRESS=LZW  -projwin %s %s %s %s %s %s",
               e@xmin,
               e@ymax,
               e@xmax,
               e@ymin,
               "tmp_map_change.tif",
               "map_change.tif"))
 
####################################################################################
#######  Classes of the map
####################################################################################
system(sprintf("oft-stat -i %s -o %s -um %s",
               "map_change.tif",
               "stats.txt",
               "map_change.tif"))

stats <- read.table("stats.txt")[,1:2]
names(stats) <- c("code","pixel_nb")
stats <- arrange(stats,code)

stats$class <- c("close_loss","close_stable","other","other_wet","open_loss","open_stable","shrub_loss","shrub_stable")
stats$prop  <- round(stats$pixel_nb/sum(stats$pixel_nb)*100,digits = 2)
stats

####################################################################################
#######   Extract the loss mask
####################################################################################
system(sprintf("gdal_calc.py -A %s --outfile=%s --co COMPRESS=LZW --calc=\"%s\"",
               "map_change.tif",
               "results_edited_20170613_pct_lossmask_AOI.tif",
               "(A==1)+(A==5)"
))

####################################################################################
####### Polygonize the patches of loss
####################################################################################
system(sprintf("gdal_polygonize.py -mask %s -f \"ESRI Shapefile\" %s %s",
               "results_edited_20170613_pct_lossmask_AOI.tif",
               "map_change.tif",
               "results_edited_20170613_pct_lossmask_AOI.shp"
))


####### Read the shapefile, create unique IDS and compute areas
shp <- readOGR("results_edited_20170613_pct_lossmask_AOI.shp","results_edited_20170613_pct_lossmask_AOI")

dbf <- shp@data
dbf$polyID <- row(dbf)[,1]
dbf$area   <- gArea(shp,byid=T)
names(dbf) <- c("map_code","polyID","area")
summary(dbf)
shp@data <- dbf

####### Re-export shapefile and rasterize
#writeOGR(shp,"db_patch_loss.shp",layer = "db_patch_loss",driver = "ESRI Shapefile")

system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               "db_patch_loss.shp",
               "map_change.tif",
               "db_patch_loss.tif",
               "polyID"
))

####### Determine centroid of each loss patch
center <- gCentroid(shp,byid = T)

################
sp_df <- SpatialPointsDataFrame(
  coords=center@coords,
  data=cbind(center@coords,dbf),
  proj4string=CRS(proj4string(shp))
)

names(sp_df) <- c("xcoord","ycoord","map_code","polyID","area")
table(sp_df@data$map_code)

####################################################################################
#######  Zonal altitude per patch
####################################################################################
system(sprintf("oft-clip.pl %s  %s  %s",
               "db_patch_loss.tif",
               altitude,
               "clip_elev_utm_5m.tif"
))

system(sprintf("oft-stat -i %s -o %s -um %s",
               "clip_elev_utm_5m.tif",
               "stats_altitude.txt",
               "db_patch_loss.tif"
))

####################################################################################
#######  Zonal slope per patch
####################################################################################
system(sprintf("oft-clip.pl %s  %s  %s",
               "db_patch_loss.tif",
               slope,
               "clip_slope_utm_5m.tif"
))

system(sprintf("oft-stat -i %s -o %s -um %s",
               "clip_slope_utm_5m.tif",
               "stats_slope.txt",
               "db_patch_loss.tif"
))

####################################################################################
#######  Zonal aspect per patch
####################################################################################
system(sprintf("oft-clip.pl %s  %s  %s",
               "db_patch_loss.tif",
               aspect,
               "clip_aspect_utm_5m.tif"
))

system(sprintf("oft-stat -i %s -o %s -um %s",
               "clip_aspect_utm_5m.tif",
               "stats_aspect.txt",
               "db_patch_loss.tif"
))

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

summary(sp_df@data)

patch_altitude <- read.table("stats_altitude.txt")
names(patch_altitude) <- c("polyID_alt","area","alt_avg","alt_std")
patch_altitude <- arrange(patch_altitude,polyID_alt)

patch_slope <- read.table("stats_slope.txt")
names(patch_slope) <- c("polyID_slp","area","slp_avg","slp_std")
patch_slope <- arrange(patch_slope,polyID_slp)

patch_aspect <- read.table("stats_aspect.txt")
names(patch_aspect) <- c("polyID_asp","area","asp_avg","asp_std")
patch_aspect <- arrange(patch_aspect,polyID_asp)

codes_ecor <- read.dbf("anmi_ecoregion_single_parts.dbf")
codes_anmi <- read.dbf("border_community_utm.dbf")

df1 <- merge(sp_df@data,codes_ecor[,c("ECOREGION","poly_id")],by.x="ecoreg",by.y="poly_id",all.x=T)
df1 <- merge(df1,codes_anmi[,c("NOMPRED","cont_treat","cod_otb","code")],by.x="anmi",by.y="code",all.x=T)
df1 <- merge(df1,stats[,c("code","class")],by.x="map_code",by.y="code",all.x=T)

df_sort <- arrange(df1,polyID)

df_sort <- cbind(df_sort,
                    over(sp_df,readOGR("ARA_ID_SIG.shp"))[,c(2,4,5)],
                    patch_altitude[,3:4],
                    patch_slope[,3:4],
                    patch_aspect[,3:4])

head(df_sort,20)
df_sort[df_sort$polyID - df_sort$polyID_alt != 0 ,]

sp_df@data <- df_sort
writeOGR(sp_df,"sampling.shp",layer="sampling",driver="ESRI Shapefile",overwrite_layer = T)

names(df_sort) <- c("map_code","anmi_code","ecoreg_code","xcoord","ycoord","point_id","patch_area","dist_road","dist_prevdf","dist_river","altitude",
               "slope","aspect","ecoreg_name","anmi_name",
               "cont_treat","cod_otb","map_class","dueno","municipio","comunidad",
               "alt_avg","alt_std","slp_avg","slp_std","asp_avg","asp_std")

df_sort1 <- df_sort[,c("point_id","xcoord","ycoord","map_class","patch_area","anmi_name","cont_treat",
             "cod_otb","ecoreg_name","dueno","municipio","comunidad",
             "dist_road","dist_river","dist_prevdf","altitude","slope","aspect",
             "alt_avg","alt_std","slp_avg","slp_std","asp_avg","asp_std")]

######## Check that final distribution of points by class is balanced between control and treatment
dff <- df_sort1[df_sort1$cont_treat %in% c("cont","treat"),]

summary(dff$patch_area)
cbind(c("count","sum","mean","SD"),
  rbind(table(df_sort1$cont_treat),
      tapply(df_sort1$patch_area,df_sort1$cont_treat,sum),
      tapply(df_sort1$patch_area,df_sort1$cont_treat,mean),
      tapply(df_sort1$patch_area,df_sort1$cont_treat,sd)
)
)

myanova <- aov(patch_area ~ cont_treat, data=dff)
myanova

(tukey <- data.frame(TukeyHSD(myanova, "cont_treat")$cont_treat))
(scheffe<-scheffe.test(myanova, "cont_treat"))

#### In terms of average loss area for RE_S2 (2011-2016)
ggplot(dff,aes(cont_treat,patch_area)) +
  stat_summary(fun.y="mean",geom="bar")+
  stat_summary(fun.data = mean_cl_normal, geom = "errorbar")+
  labs(x = "", 
       y = "Loss patch area (ha)", 
       title = "Average Loss patch area with RE_S2 (2011-2016)")

#### In terms of average loss area for RE_S2 (2011-2016)
ggplot(dff,aes(cont_treat,patch_area)) + geom_boxplot()

######## Check that final distribution of points by class is balanced between ECOREGIONs
table(df_sort1$ecoreg_name)

######## 
plot(df_sort1$altitude,df_sort1$alt_avg)

######## Loss as relation to previous deforestation (the further away the less likely)
hist(log(df_sort1$patch_area))

######## Loss as relation to previous deforestation (the further away the less likely)
hist(log(df_sort1$dist_prevdf))

######## Loss as relation to accessibility (the further away the less likely)
hist(log(df_sort1$dist_road))

write.csv(df_sort1,"dataset_patch_20170615.csv",row.names = F)

