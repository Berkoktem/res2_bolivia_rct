####################################################################################
####### Object:  Merge zonal stats from different products into final database            
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/03/09                                         
####################################################################################

#zonal_dir <- "/home/dannunzio/Documents/bolivia_rct/zonal_stats/"
setwd(zonal_dir)
####################################################################################
#######  Change map
####################################################################################

dbf <- read.dbf(paste0(anmi_dir,"/","community_boundaries/","border_community_utm.dbf"))

############################### By ANMI community for CHDET product
his <- read.table(
  paste0(zonal_dir,"zonal_chdt_bolivia_rct_20170324_closed_",size_morpho,"mask_ecoregion.txt")
)

names(his) <- c("zone","total_px","nodata_px","loss_px","forest_px","non_forest_px","water_px",
                "openf_loss_px","openf_stable_px",
                "shrub_loss_px","shrub_stable_px")

############################### Compute real areas
pixel_size <- 5
his[,(ncol(his)+1):(2*ncol(his)-1)] <- his[,2:ncol(his)]*pixel_size*pixel_size/10000

names(his) <- c("zone","total_px_res2","nodata_px_res2","loss_px_res2","forest_px_res2","non_forest_px_res2","water_px_res2",
                "openf_loss_px_res2","openf_stable_px_res2",
                "shrub_loss_px_res2","shrub_stable_px_res2",
                       "total_ha_res2","nodata_ha_res2","loss_ha_res2","forest_ha_res2","non_forest_ha_res2","water_ha_res2",
                "openf_loss_ha_res2","openf_stable_ha_res2",
                "shrub_loss_ha_res2","shrub_stable_ha_res2"
                )


####################################################################################
#######          COMPUTE ZONAL STATS
####################################################################################

############################### By ANMI community for DEM product
zonal_elev  <- read.table(paste0(zonal_dir,"zonal_elev.txt"))
zonal_slope <- read.table(paste0(zonal_dir,"zonal_slope.txt"))

names(zonal_elev ) <- c("zone","total_px_dem","elev_mean","elev_std")
names(zonal_slope ) <- c("zone","total_px_dem","slope_mean","slope_std")

dem <- cbind(zonal_elev,zonal_slope[,3:4])
summary(zonal_elev$total-zonal_slope$total)

pixel_size <- 30.0439

dem$total_ha_dem <- dem$total_px_dem*pixel_size*pixel_size/10000

############################### By ANMI community for GFC loss product
his_ly <- read.table(paste0(zonal_dir,"zonal_gfc_ly_70.txt"))
his_tc <- read.table(paste0(zonal_dir,"zonal_gfc_tc_70.txt"))

names(his_ly) <- c("zone","total_px_ly","noloss_px_ly",paste0("loss_px_ly_",1:14))
names(his_tc) <- c("zone","total_px_ly","noforest_px_ly","forest_px_ly")

pixel_size <- 29.1977

his_tc[,(ncol(his_tc)+1):(2*ncol(his_tc)-1)] <- his_tc[,2:ncol(his_tc)]*pixel_size*pixel_size/10000
his_ly[,(ncol(his_ly)+1):(2*ncol(his_ly)-1)] <- his_ly[,2:ncol(his_ly)]*pixel_size*pixel_size/10000

names(his_ly) <- c("zone","total_px_ly","noloss_px_ly",paste0("loss_px_ly_",1:14),
                          "total_ha_ly","noloss_ha_ly",paste0("loss_ha_ly_",1:14))

names(his_tc) <- c("zone","total_px_tc","no_tc_px","tc_px",
                          "total_ha_tc","no_tc_ha","tc_ha")

####################################################################################
#######          COMPUTE ZONAL STATS FOR ECOREGIONS
####################################################################################

############################### By ANMI community for DEM product
ecoreg <- read.table(paste0(zonal_dir,"hist_ecoregions.txt"))
#dbf_ecoreg <- read.dbf(paste0(zonal_dir,"ecoregion_single_parts.dbf"))
dbf_ecoreg <- read.dbf(paste0(eco_dir,"ANMI_Ecoregions_P.dbf"))
names(dbf_ecoreg)

list_ecozones <- dbf_ecoreg$ID_C

nb_ecozones <- ncol(ecoreg)-3

names(ecoreg) <- c("zone","total_px_ecoregion","nodata_eco",paste0("eco_",1:nb_ecozones))
head(ecoreg)

pixel_size <- 5

ecoreg[,(ncol(ecoreg)+1):(2*ncol(ecoreg)-1)] <- ecoreg[,2:ncol(ecoreg)]* pixel_size * pixel_size / 10000
names(ecoreg) <- c("zone",
                   "total_px_ecoregion","nodata_eco_px",paste0("eco_px_",1:nb_ecozones),
                   "total_ha_ecoregion","nodata_eco_ha",paste0("eco_ha_",1:nb_ecozones)
                   )                                                       


names(dem)
names(his_ly)
names(his_tc)
names(his)
names(ecoreg)


df <- merge(his,his_tc) 
df <- merge(df,his_ly)
df <- merge(df,ecoreg)
df1 <- merge(df,dem)

df <- merge(x = df1,
               y = dbf[,c("NOMPRED","cont_treat","cod_otb","code","area_ha")],
               by.x="zone",
               by.y="code",
               all=T)

df$loss_11_14_px <- df$loss_px_ly_11  + df$loss_px_ly_12  + df$loss_px_ly_13  + df$loss_px_ly_14
df$tc_2011_px    <- df$tc_px - rowSums(df[,paste0("loss_px_ly_",1:10)])

df$loss_11_14_ha <- df$loss_ha_ly_11  + df$loss_ha_ly_12  + df$loss_ha_ly_13  + df$loss_ha_ly_14
df$tc_2011_ha    <- df$tc_ha - rowSums(df[,paste0("loss_ha_ly_",1:10)])

head(df)
df$loss_pct <- df$loss_11_14_ha / df$tc_2011_ha * 100

df <- df[!is.na(df$loss_pct),]

tapply(df$loss_pct,df$cont_treat,mean)
tapply(df$tc_2011_px,df$cont_treat,sum)
tapply(df$loss_11_14_px,df$cont_treat,sum)

#write.csv(df,"../stats_raw_db.csv",row.names = F)
names(df)

out <- df[,c( "zone","NOMPRED","cont_treat","cod_otb","area_ha",
              "total_ha_res2","nodata_ha_res2","loss_ha_res2","forest_ha_res2","non_forest_ha_res2","water_ha_res2",
              "openf_loss_ha_res2","openf_stable_ha_res2",
              "shrub_loss_ha_res2","shrub_stable_ha_res2",
              "total_ha_tc","no_tc_ha","tc_ha",
              "total_ha_ly","noloss_ha_ly","loss_ha_ly_1","loss_ha_ly_2","loss_ha_ly_3","loss_ha_ly_4","loss_ha_ly_5","loss_ha_ly_6","loss_ha_ly_7","loss_ha_ly_8","loss_ha_ly_9","loss_ha_ly_10","loss_ha_ly_11","loss_ha_ly_12","loss_ha_ly_13","loss_ha_ly_14",
              "total_ha_dem","elev_mean","elev_std","slope_mean","slope_std",
              "loss_11_14_ha",     
              "tc_2011_ha",
              "total_ha_ecoregion","nodata_eco_ha",paste0("eco_ha_",list_ecozones)
              )
          ]

write.csv(out,paste0(rootdir,"stats_db_ecoregions_20170324.csv"),row.names = F)

plot(df$total_ha_res2,df$total_ha_ecoregion)
plot(df$total_ha_res2,df$total_ha_tc)

summary(df$total_ha_res2 - rowSums(df[,c("nodata_ha_res2","loss_ha_res2","forest_ha_res2","non_forest_ha_res2","water_ha_res2",
                                        "openf_loss_ha_res2","openf_stable_ha_res2",
                                        "shrub_loss_ha_res2","shrub_stable_ha_res2")]))
