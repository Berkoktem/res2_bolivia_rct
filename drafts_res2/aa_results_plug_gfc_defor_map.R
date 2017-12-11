####################################################################################################
####################################################################################################
## GET REFERENCE DATA FROM AD GRID FOR ACCURACY ASSESSMENT OF RESULTS
## Contact remi.dannunzio@fao.org 
## 2017/12/01
####################################################################################################
####################################################################################################

#### READ THE COLLECTED REFERENCE POINTS GRID 
df    <- read.csv(paste0(rootdir,"results_AA_tcc_map/remitest_collectedData_earthaa_aa_rct_bolivia_20170411_on_240417_150410_CSV.csv"))
map   <- raster(paste0(gfc_dir,"defor_map_gfc16.tif"))

code <- data.frame(cbind(c(0:4),c("nodata","forest","other","old_loss","loss")))
names(code) <- c("gfc_map_code","gfc_map_class")

#### SPATIALIZE THE POINTS
spdf <- SpatialPointsDataFrame(coords = df[,c("location_x","location_y")],
                               data   = df,
                               proj4string = CRS("+init=epsg:4326"))

#### INTERSECT WITH MAP
proj4string(map)       <- proj4string(spdf)
spdf@data$gfc_map_code <- extract(map,spdf)

df1 <- spdf@data
df1[df1$gfc_map_code == 3,]$gfc_map_code <- 2
df2 <- merge(df1,code,by.x="gfc_map_code",by.y="gfc_map_code",all.x=T)

df2 <- df2[df2$gfc_map_code != 0,]
table(df2$gfc_map_code)
write.csv(df2,paste0(rootdir,"results_AA_tcc_map/map_vs_ref_20171201.csv"),row.names = F)

table(df2$gfc_map_class,df2$ref_class_label)
######## Confusion matrix as count of elements
map_code <- "gfc_map_code"
ref_code <- "ref_class_label"
legend <- levels(as.factor(df2[,ref_code]))

tmp <- as.matrix(table(df2[,map_code,],df2[,ref_code]))

tmp[is.na(tmp)]<- 0

matrix<-matrix(0,nrow=length(legend),ncol=length(legend))

for(i in 1:length(legend)){
  tryCatch({
    cat(paste(legend[i],"\n"))
    matrix[,i]<-tmp[,legend[i]]
  }, error=function(e){cat("Not relevant\n")}
  )
}

matrix

#### COMPUTE MAP AREAS
system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               paste0(gfc_dir,"defor_map_gfc16_utm.tif"),
               paste0(gfc_dir,"stats_defor_map_gfc16.txt"),
               paste0(gfc_dir,"defor_map_gfc16_utm.tif")
))

areas <- read.table(paste0(gfc_dir,"stats_defor_map_gfc16.txt"))[,1:2]
names(areas) <- c("map_code","map_area")
areas$map_code_agg <- areas$map_code
areas[areas$map_code == 3,]$map_code_agg <- 2
areas_agg <- data.frame(cbind(c("forest","other","loss"),tapply(areas$map_area,areas$map_code_agg,sum)))
names(areas_agg) <- c("map_code","map_area")

write.csv(areas_agg,paste0(gfc_dir,"stats_defor_map_gfc16.csv"),row.names = F)
