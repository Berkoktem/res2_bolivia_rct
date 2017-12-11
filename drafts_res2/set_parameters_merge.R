####################################################################################
####### Object:  Prepare names for merging of intermediate products                 
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/02/05                                         
####################################################################################

################################################################################
## Create an output directory for the change products
imaddir    <- paste0(rootdir,"results/",re_tile,"/imad")
res_se_dir <- paste0(rootdir,"results/",re_tile,"/se")
res_re_dir <- paste0(rootdir,"results/",re_tile,"/re")
mergedir   <- paste0(rootdir,"results/",re_tile,"/change")

system(sprintf("mkdir %s",mergedir))

####################################################################################
#######          INPUTS FROM IMAD AND CLASSIFICATIONS
####################################################################################
imad      <-  paste0(imaddir,"/tile_",re_tile,"_imad.tif")        # imad name
re_file   <-  paste0(res_re_dir,"/tile_",re_tile,"_re_output.tif")   # rapideye_file
se_file   <-  paste0(res_se_dir,"/tile_",re_tile,"_se_output.tif")   # sentinel_file

########################################
## OUTPUTS OF MERGE

segs_id   <- paste0(mergedir,"/tile_",re_tile,"_all_segs_id.tif")    # id of each objects (sentinel base)

se_cl_st  <- paste0(mergedir,"/tile_",re_tile,"_se_class_stats.txt") # stats of Sentinel classification 
re_cl_st  <- paste0(mergedir,"/tile_",re_tile,"_re_class_stats.txt") # stats of RapidEye classification 
im_cl_st  <- paste0(mergedir,"/tile_",re_tile,"_im_class_stats.txt") # stats of IMAD change detection 

reclass   <- paste0(mergedir,"/tile_",re_tile,"_reclass.txt") # reclassified stats
reclass_shrub <- paste0(mergedir,"/tile_",re_tile,"_reclass_shrub.txt") # reclassified stats

chg_class <-paste0(mergedir,"/tile_",re_tile,"_change_reclass.tif") # reclassified tif
chg_class_shrub <- paste0(mergedir,"/tile_",re_tile,"_change_reclass_shrub.tif") # reclassified tif
