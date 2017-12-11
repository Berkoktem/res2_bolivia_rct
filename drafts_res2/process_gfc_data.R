####################################################################################
####### Object:  Process GFC data over the zone             
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/02/05                                         
####################################################################################

####################################################################################
#######          COMPUTE FOREST MASK FROM TREE COVER THRESHOLD
####################################################################################
system(sprintf("gdal_calc.py -A %s --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_tc_bolivia_rct.tif"),
               paste0(gfc_dir,"tmp_gfc_tc_",thresh_gfc,".tif"),
               paste0("A>",thresh_gfc)
               )
       )

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(gfc_dir,"tmp_gfc_tc_",thresh_gfc,".tif"),
               paste0(gfc_dir,"gfc_tc_",thresh_gfc,".tif")
               ))

####################################################################################
#######          MASK OUT LOSS FROM THRESHOLD
####################################################################################
system(sprintf("gdal_calc.py -A %s -B %s --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_tc_",thresh_gfc,".tif"),
               paste0(gfc_dir,"gfc_ly_bolivia_rct.tif"),
               paste0(gfc_dir,"tmp_gfc_ly_",thresh_gfc,".tif"),
               paste0("A*B")
)
)

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(gfc_dir,"tmp_gfc_ly_",thresh_gfc,".tif"),
               paste0(gfc_dir,"gfc_ly_",thresh_gfc,".tif")
))

####################################################################################
#######          COMPUTE ZONAL STATISTICS FOR FORESTS AND LOSS PRODUCT
####################################################################################
system(sprintf("oft-zonal.py -um %s -i %s -o %s -a code",
               paste0(anmi_dir,"/","community_boundaries/","border_community_utm.shp"),
               paste0(gfc_dir,"gfc_tc_",thresh_gfc,".tif"),
               paste0(zonal_dir,"zonal_gfc_tc_",thresh_gfc,".txt")
))

system(sprintf("oft-zonal.py -um %s -i %s -o %s -a code",
               paste0(anmi_dir,"/","community_boundaries/","border_community_utm.shp"),
               paste0(gfc_dir,"gfc_ly_",thresh_gfc,".tif"),
               paste0(zonal_dir,"zonal_gfc_ly_",thresh_gfc,".txt")
))

system(sprintf("oft-zonal.py -um %s -i %s -o %s -a code",
               paste0(anmi_dir,"/","community_boundaries/","border_community_utm.shp"),
               paste0(gfc_dir,"gfc_tc_bolivia_rct.tif"),
               paste0(zonal_dir,"zonal_gfc_all.txt")
))

system(sprintf(paste0("rm ",gfc_dir,"/","tmp_*.tif")))
####################################################################################
#######          COMPUTE ZONAL STATS
####################################################################################

dbf <- read.dbf(paste0(anmi_dir,"/","community_boundaries/","border_community_utm.dbf"))


############################### By ANMI community for GFC loss product
his_ly <- read.table(paste0(anmi_dir,"/","zonal_gfc_ly_",thresh_gfc,".txt"))
his_tc <- read.table(paste0(anmi_dir,"/","zonal_gfc_tc_",thresh_gfc,".txt"))
his_all<- read.table(paste0(anmi_dir,"/","zonal_gfc_all.txt"))

names(his_ly) <- c("zone","total","noloss",paste0("loss_",1:14))
names(his_tc) <- c("zone","total","noforest","forest")
names(his_all)<- c("zone","total","noforest",paste0("tc",1:100))

pixel_size <- 29.1977

cumulated_sum_gfc <- cumsum(colSums(his_all[,103:3])*pixel_size*pixel_size/10000)
plot(cumulated_sum_gfc)
write.csv(his_all,paste0(anmi_dir,"/","zonal_gfc_tc_all.csv"),row.names = F)

his_tc[,2:ncol(his_tc)] <- his_tc[,2:ncol(his_tc)]*pixel_size*pixel_size/10000
his_ly[,2:ncol(his_ly)] <- his_ly[,2:ncol(his_ly)]*pixel_size*pixel_size/10000


df_ly <- merge(x = his_ly,
               y = dbf[,c("NOMPRED","cont_treat","cod_otb","code","area_ha")],
               by.x="zone",
               by.y="code",
               all=T)

df_tc <- merge(x = df_ly,
               y = his_tc[,c("zone","noforest","forest")],
               all=T)

df_tc$loss <- df_tc$loss_11  + df_tc$loss_12  + df_tc$loss_13  + df_tc$loss_14
df_tc$for2010<- df_tc$forest - rowSums(df_tc[,paste0("loss_",1:10)])

head(df_tc)
df_tc$loss_pct <- df_tc$loss / df_tc$for2010

df2 <- df_tc
df <- df2[!is.na(df2$loss_pct),]

tapply(df$loss_pct,df$cont_treat,mean)
tapply(df$forest,df$cont_treat,sum)
tapply(df$loss,df$cont_treat,sum)
sum(df$forest)
write.csv(df,paste0(anmi_dir,"/","zonal_gfc_tc_",thresh_gfc,".csv"),row.names = F)
