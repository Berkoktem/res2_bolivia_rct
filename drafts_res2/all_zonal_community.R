####################################################################################
####### Object:  Process GFC data over the zone             
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/09/20                                         
####################################################################################

####### Forest change map
res2 <- paste0(workdir,"results_edited_20170613.tif")

####### Boundaries ANMI shapefile
bound <- paste0(anmi_dir,"/","community_boundaries/","communities_UTM20_20170913.shp")

####### Community boundaries TIF
anmi <- paste0(anmi_dir,"/","community_boundaries/","communities_UTM20_20170913.tif")

system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               bound,
               res2,
               anmi,
               "int_code"
))


####################################################################################
#######          COMPUTE ZONAL STATISTICS FOR FORESTS AND LOSS PRODUCT
####################################################################################
system(sprintf("oft-zonal_large_list.py -um %s -i %s -o %s -a %s",
               bound,
               paste0(gfc_dir,"gfc_tc_",thresh_gfc,".tif"),
               paste0(zonal_dir,"zonal_gfc_tc_",thresh_gfc,".txt"),
               "int_code"
))

system(sprintf("oft-zonal_large_list.py -um %s -i %s -o %s -a %s",
               bound,
               paste0(gfc_dir,"gfc_ly_",thresh_gfc,".tif"),
               paste0(zonal_dir,"zonal_gfc_ly_",thresh_gfc,".txt"),
               "int_code"
))

system(sprintf("oft-zonal_large_list.py -um %s -i %s -o %s -a %s",
               bound,
               paste0(gfc_dir,"gfc_tc_bolivia_rct.tif"),
               paste0(zonal_dir,"zonal_gfc_all.txt"),
               "int_code"
))


####################################################################################
#######          COMPUTE ZONAL STATS FOR DEM
####################################################################################
system(sprintf("oft-clip.pl %s %s %s ",
               paste0(rootdir,"dem_bolivia_rct/clip_elev_utm.tif"),
               anmi,
               paste0(anmi_dir,"/","community_boundaries/","border_community_utm_4_elev.tif")
))

####################################################################################
#######  Zonal stats of DEM
system(sprintf("oft-stat -i %s -o %s -um %s",
               paste0(rootdir,"dem_bolivia_rct/clip_elev_utm.tif"),
               paste0(zonal_dir,"zonal_elev.txt"),
               paste0(anmi_dir,"/","community_boundaries/","border_community_utm_4_elev.tif")
))

####################################################################################
#######  Zonal stats of SLOPE
system(sprintf("oft-stat -i %s -o %s -um %s",
               paste0(rootdir,"dem_bolivia_rct/clip_slope_utm.tif"),
               paste0(zonal_dir,"zonal_slope.txt"),
               paste0(anmi_dir,"/","community_boundaries/","border_community_utm_4_elev.tif")
))


####################################################################################
#######  Zonal stats over ecoregions
system(sprintf("oft-zonal_large_list.py -um %s -i %s -o %s -a %s",
               bound,
               paste0(eco_dir,"ecoregion_single_parts.tif"),
               paste0(zonal_dir,"hist_ecoregions.txt"),
               "int_code"
))
