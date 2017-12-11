####################################################################################
####### Object:  Process GFC data over the zone             
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/02/05                                         
####################################################################################

####################################################################################
#######          CREATE ANMI MASK
####################################################################################
system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a int_code",
               paste0(anmi_dir,"/","community_boundaries/","communities_geo_20171129.shp"),
               paste0(gfc_dir,"gfc_2016_tc_",thresh_gfc,".tif"),
               paste0(anmi_dir,"/","community_boundaries/","communities_geo_20171129.tif")
))

####################################################################################
#######          COMPUTE FOREST MASK FROM TREE COVER THRESHOLD
####################################################################################
system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --type=Byte --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_2016_bb_treecover2000.tif"),
               paste0(gfc_dir,"gfc_2016_tc_",thresh_gfc,".tif"),
               paste0("A>",thresh_gfc)
               )
       )

####################################################################################
#######          MASK OUT LOSS FROM THRESHOLD
####################################################################################
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --type=Byte --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_2016_tc_",thresh_gfc,".tif"),
               paste0(gfc_dir,"gfc_2016_bb_lossyear.tif"),
               paste0(gfc_dir,"gfc_2016_ly_",thresh_gfc,".tif"),
               paste0("A*B")
)
)

####################################################################################
#######          NEW DEFORESTATION MAP
####################################################################################
system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --type=Byte --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_2016_tc_",thresh_gfc,".tif"), ## TREE COVER 
               paste0(gfc_dir,"gfc_2016_ly_",thresh_gfc,".tif"), ## LOSS YEAR
               paste0(anmi_dir,"/","community_boundaries/","communities_geo_20171129.tif"), ## MASK
               paste0(gfc_dir,"defor_map_gfc16.tif"),
               paste0("((A==0)*2+(A>0)*((B==0)*1+(B>0)*(B<11)*3+(B>10)*4))*(C>0)") # 1 == forest, 2== non forest, 3 == old loss, 4 == recent loss, 0 == no data
)
)

system(sprintf("gdalwarp -srcnodata none -co COMPRESS=LZW -t_srs EPSG:32720 %s %s",
               paste0(gfc_dir,"defor_map_gfc16.tif"),
               paste0(gfc_dir,"defor_map_gfc16_utm.tif")
))

####################################################################################
#######          HISTORICAL LOSS WITHIN AOI
####################################################################################
system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --type=Byte --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_2016_ly_",thresh_gfc,".tif"),
               paste0(anmi_dir,"/","community_boundaries/","communities_geo_20171129.tif"),
               paste0(gfc_dir,"gfc_2016_aoi_loss_2000_2010.tif"),
               paste0("(A>0)*(A<11)*(B>0)")
)
)

system(sprintf("gdalwarp -t_srs EPSG:32720 %s %s",
               paste0(gfc_dir,"gfc_2016_aoi_loss_2000_2010.tif"),
               paste0(gfc_dir,"gfc_2016_aoi_loss_2000_2010_utm.tif")
               ))

####################################################################################
#######          RCT PERIOD LOSS WITHIN AOI
####################################################################################
system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --type=Byte --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_2016_ly_",thresh_gfc,".tif"),
               paste0(anmi_dir,"/","community_boundaries/","communities_geo_20171129.tif"),
               paste0(gfc_dir,"gfc_2016_aoi_loss_2011_2016.tif"),
               paste0("(A>10)*(B>0)")
)
)

system(sprintf("gdalwarp -t_srs EPSG:32720 %s %s",
               paste0(gfc_dir,"gfc_2016_aoi_loss_2011_2016.tif"),
               paste0(gfc_dir,"gfc_2016_aoi_loss_2011_2016_utm.tif")
))

####################################################################################
#######          COMPUTE ZONAL STATISTICS FOR FORESTS AND LOSS PRODUCT
####################################################################################
system(sprintf("oft-zonal.py -um %s -i %s -o %s -a int_code",
               paste0(anmi_dir,"/","community_boundaries/","communities_geo_20171129.shp"),
               paste0(gfc_dir,"gfc_2016_tc_",thresh_gfc,".tif"),
               paste0(zonal_dir,"zonal_gfc2016_tc_",thresh_gfc,".txt")
))

system(sprintf("oft-zonal.py -um %s -i %s -o %s -a int_code",
               paste0(anmi_dir,"/","community_boundaries/","communities_geo_20171129.shp"),
               paste0(gfc_dir,"gfc_2016_ly_",thresh_gfc,".tif"),
               paste0(zonal_dir,"zonal_gfc2016_ly_",thresh_gfc,".txt")
))

system(sprintf("oft-zonal.py -um %s -i %s -o %s -a int_code",
               paste0(anmi_dir,"/","community_boundaries/","communities_geo_20171129.shp"),
               paste0(gfc_dir,"gfc_2016_bb_treecover2000.tif"),
               paste0(zonal_dir,"zonal_gfc2016_all.txt")
))

####################################################################################
#######          COMPUTE ZONAL STATS
####################################################################################

dbf <- read.dbf(paste0(anmi_dir,"/","community_boundaries/","communities_geo_20171129.dbf"))
names(dbf)

############################### By ANMI community for GFC loss product
his_ly <- read.table(paste0(zonal_dir,"/","zonal_gfc2016_ly_",thresh_gfc,".txt"))
his_tc <- read.table(paste0(zonal_dir,"/","zonal_gfc2016_tc_",thresh_gfc,".txt"))
his_all<- read.table(paste0(zonal_dir,"/","zonal_gfc2016_all.txt"))

names(his_ly) <- c("zone","total","noloss",paste0("loss_",1:16))
names(his_tc) <- c("zone","total_tc","no_tc2000","tc_2000")
names(his_all)<- c("zone","total","no_tc2000",paste0("tc",1:100))

# system(sprintf("gdalwarp -t_srs EPSG:32720 %s %s",
#                paste0(gfc_dir,"gfc_2016_bb_datamask.tif"),
#                paste0(gfc_dir,"gfc_2016_bb_datamask_utm.tif")
#                ))

pixel_size <- res(raster(paste0(gfc_dir,"gfc_2016_bb_datamask_utm.tif")))

cumulated_sum_gfc <- cumsum(colSums(his_all[,103:3])*pixel_size*pixel_size/10000)
plot(cumulated_sum_gfc)
write.csv(his_all,paste0(anmi_dir,"/","zonal_gfc_tc_all.csv"),row.names = F)

his_tc[,2:ncol(his_tc)] <- his_tc[,2:ncol(his_tc)]*pixel_size*pixel_size/10000
his_ly[,2:ncol(his_ly)] <- his_ly[,2:ncol(his_ly)]*pixel_size*pixel_size/10000


df_ly <- merge(x = his_ly,
               y = dbf[,c("NOMPRED","cont_treat","ID_OTB","int_code","area_shapefile")],
               by.x="zone",
               by.y="int_code",
               all=T)

df_tc <- merge(x = df_ly,
               y = his_tc[,c("zone","total_tc","no_tc2000","tc_2000")],
               all=T)

df_tc$loss_11_16 <- rowSums(df_tc[,paste0("loss_",11:16)])
df_tc$loss_00_10 <- rowSums(df_tc[,paste0("loss_",1:10)])

df_tc$tc_2010    <- df_tc$tc_2000 - df_tc$loss_00_10
df_tc$tc_2016    <- df_tc$tc_2010 - df_tc$loss_11_16

df_tc$loss_pct_00_10 <- df_tc$loss_00_10 / df_tc$tc_2000 *100
df_tc$loss_pct_11_16 <- df_tc$loss_11_16 / df_tc$tc_2010 *100

df <- df_tc

tapply(df$loss_pct_00_10,df$cont_treat,mean)
tapply(df$loss_pct_11_16,df$cont_treat,mean)

tapply(df$tc_2000,df$cont_treat,sum)
tapply(df$tc_2010,df$cont_treat,sum)
tapply(df$tc_2016,df$cont_treat,sum)

ggplot(df,aes(loss_pct_00_10,loss_pct_11_16,colour=cont_treat))+ geom_point()
ggplot(df,aes(loss_00_10,loss_11_16,colour=cont_treat))+ geom_point()
ggplot(df,aes(tc_2000,tc_2016,colour=cont_treat))+ geom_point()

df <- df[,c("NOMPRED","ID_OTB","area_ha","cont_treat",
            "total","noloss","loss_1","loss_2","loss_3","loss_4","loss_5","loss_6","loss_7","loss_8","loss_9",
            "loss_10","loss_11","loss_12","loss_13","loss_14","loss_15","loss_16",
            "total_tc","no_tc2000","tc_2000","tc_2010","tc_2016","loss_00_10","loss_11_16",
            "loss_pct_00_10","loss_pct_11_16")]

names(df)
write.csv(df,paste0(anmi_dir,"/","zonal_gfc2016_tc_",thresh_gfc,".csv"),row.names = F)
