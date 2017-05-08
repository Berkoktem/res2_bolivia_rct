####################################################################################
####### Object:  Merge tiles and compute zonal statistics               
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/02/05                                         
####################################################################################

####################################################################################
#######          MERGE TILES AND FINALIZE
####################################################################################
# system(sprintf("gdal_merge.py -o %s -v -ot byte -co COMPRESS=LZW %s",
#                paste0(result_dir,"tmp_reclass.tif"),
#                paste0(result_dir,"*/change/*reclass.tif")
# )
# )
# 
# system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
#                paste0(result_dir,"/","tmp_reclass.tif"),
#                paste0(anmi_dir,"/","chdt_bolivia_rct_20170204_imad1000_tc70_size36.tif")))

system(sprintf("gdal_merge.py -o %s -v -ot byte -co COMPRESS=LZW %s",
               paste0(result_dir,"tmp_reclass.tif"),
               paste0(result_dir,"*/change/*reclass_shrub.tif")
)
)

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(result_dir,"/","tmp_reclass.tif"),
               paste0(rootdir,"results_merged/chdt_bolivia_rct_20170321.tif")))

source("close_holes_morphology.R")

system(sprintf("oft-zonal.py -um %s -i %s -o %s -a code",
               paste0(anmi_dir,"/","community_boundaries/","border_community_utm.shp"),
               paste0(workdir,"chdt_bolivia_rct_20170320_closed_",size_morpho,".tif"),
               paste0(zonal_dir,"zonal_chdt_bolivia_rct_20170321_closed_",size_morpho,".txt")
))

system(sprintf("oft-zonal.py -um %s -i %s -o %s -a code",
               paste0(anmi_dir,"/","community_boundaries/","border_community_utm.shp"),
               paste0(workdir,"chdt_closed_mask_ecoregion_pct_20170324.tif"),
               paste0(zonal_dir,"zonal_chdt_bolivia_rct_20170324_closed_",size_morpho,"mask_ecoregion.txt")
))


