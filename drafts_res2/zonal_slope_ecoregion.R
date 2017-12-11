####################################################################################
####### Object:  Merge tiles and compute zonal statistics               
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/02/05                                         
####################################################################################
zonal_dir <- paste0(rootdir,"zonal_stats/")

####################################################################################
#######  Rasterize community borders
system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a code",
               paste0(anmi_dir,"/","community_boundaries/","border_community_utm.shp"),
               paste0(workdir,"chdt_bolivia_rct_20170321_closed_",size_morpho,".tif"),
               paste0(anmi_dir,"/","community_boundaries/border_community_utm.tif")
))

system(sprintf("oft-clip.pl %s %s %s ",
               paste0(rootdir,"dem_bolivia_rct/clip_elev_utm.tif"),
               paste0(anmi_dir,"/","community_boundaries/","border_community_utm.tif"),
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

# system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
#                paste0(eco_dir,"ecoregion_single_parts.shp"),
#                paste0(workdir,"chdt_bolivia_rct_20170320_closed_",size_morpho,".tif"),
#                paste0(eco_dir,"ecoregion_single_parts.tif"),
#                "code_remi"
# ))

####################################################################################
#######  Rasterize ecoregions
system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               paste0(eco_dir,"anmi_ecoregion_single_parts.shp"),
               paste0(workdir,"chdt_bolivia_rct_20170321_closed_",size_morpho,".tif"),
               paste0(eco_dir,"anmi_ecoregion_single_parts.tif"),
               "poly_id"
))


####################################################################################
#######  Zonal stats over ecoregions
system(sprintf("oft-zonal.py -i %s  -um %s -o %s",
               paste0(eco_dir,"ecoregion_single_parts.tif"),
               paste0(anmi_dir,"community_boundaries/border_community_utm.tif"),
               paste0(eco_dir,"hist_ecoregions.txt")
))


####################################################################################
#######  Combine ecoregion and map to differentiate dry-open forests areas
system(sprintf("gdal_calc.py -A %s -B %s --outfile=%s --calc=\"%s\"",
               paste0(eco_dir,"anmi_ecoregion_single_parts.tif"),
               paste0(workdir,"chdt_bolivia_rct_20170321_closed_",size_morpho,".tif"),
               paste0(workdir,"tmp_chdt_closed_mask_ecoregion.tif"),
               paste0("(1-((A==7)+(A==10)+(A==11)+(A==15)+(A==37)+(A==38)+(A==43)))*((B==6)*8+(B==5)*7+(B<5)*B)+((A==7)+(A==10)+(A==11)+(A==15)+(A==37)+(A==38)+(A==43))*B")
)
)




################################################################################
## Add pseudo color table to result

#### Create PCT
pct <- data.frame(cbind(
  0:8,
  c("black","red","darkgreen","gray85","gray90","red","darkolivegreen","gray55","gray80")
))

#### EXPORT PCT
pct1 <- data.frame(cbind(pct$X1,col2rgb(pct$X2)[1,],col2rgb(pct$X2)[2,],col2rgb(pct$X2)[3,]))
write.table(pct1,paste0(workdir,"color_table.txt"),row.names = F,col.names = F,quote = F)

#### ADD PCT
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(workdir,"color_table.txt"),
               paste0(workdir,"tmp_chdt_closed_mask_ecoregion.tif"),
               paste0(workdir,"tmp_chdt_closed_mask_ecoregion_pct.tif")
))

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(workdir,"tmp_chdt_closed_mask_ecoregion_pct.tif"),
               paste0(workdir,"chdt_closed_mask_ecoregion_pct_20170324.tif")
))
