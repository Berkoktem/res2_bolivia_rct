####################################################################################
####### Object:  Merge tiles and compute zonal statistics               
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/02/05                                         
####################################################################################

####################################################################################
#######          MERGE TILES AND FINALIZE
####################################################################################
system(sprintf("gdal_merge.py -o %s -v -ot byte -co COMPRESS=LZW %s",
               paste0(result_dir,"tmp_reclass.tif"),
               paste0(result_dir,"*/change/*reclass.tif")
)
)

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(result_dir,"/","tmp_reclass.tif"),
               paste0(anmi_dir,"/","chdt_bolivia_rct_20170204_imad1000_tc70_size36.tif")))


system(sprintf("oft-zonal.py -um %s -i %s -o %s -a code",
               paste0(anmi_dir,"/","community_boundaries/","border_community_utm.shp"),
               paste0(anmi_dir,"/","chdt_bolivia_rct_20170204_imad1000_tc70_size36.tif"),
               paste0(anmi_dir,"/","zonal_chdt_imad1000_tc70_size36.txt")
))

####################################################################################
#######          COMPUTE ZONAL STATS
####################################################################################

dbf <- read.dbf(paste0(anmi_dir,"/","community_boundaries/","border_community_utm.dbf"))

############################### By ANMI community for CHDET product
his <- read.table(paste0(anmi_dir,"/","zonal_chdt_imad1000_tc70_size36.txt"))

names(dbf)
names(his) <- c("zone","total","nodata","loss","forest","non_forest","water")

############################### Compute real areas
pixel_size <- 5
his[,2:ncol(his)] <- his[,2:ncol(his)]*pixel_size*pixel_size/10000

############################### Merge Community shapefile with zonal statistics
df <- merge(x = his,
            y = dbf[,c("NOMPRED","cont_treat","cod_otb","code","area_ha")],
            by.x="zone",
            by.y="code",
            all=T)

############################### Compute percentage loss
df$loss_pct <- df$loss / df$forest
df1 <- df
df <- df1[!is.na(df1$loss_pct),]

############################### Compute sum of forest and loss
tapply(df$loss_pct,df$cont_treat,mean)
tapply(df$forest,df$cont_treat,sum)
tapply(df$loss,df$cont_treat,sum)
sum(df$forest)

############################### Export results as CSV file
write.csv(df,paste0(anmi_dir,"/","zonal_chdt_imad1000_tc70_size36.csv"),row.names = F)

