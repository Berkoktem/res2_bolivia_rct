####################################################################################
####### Object:  Processing chain                
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/02/05                                       
####################################################################################
setwd("/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/bolivia/scripts/scripts_bolivia_rct/")

####################################################################################
#######          INPUTS
####################################################################################
source("set_parameters_master.R",echo=TRUE)

#done <- unique(substr(basename(list.files(path = re_dir, pattern="_output.tif",recursive = T)),1,7))
#done <- basename(list.dirs(result_dir,recursive = F))
done <- list()
todo <- select$re_index[!(select$re_index %in% done)]

re_tile <- todo[1]

####################################################################################
#######          LOOP THROUGH EACH TILE
####################################################################################
for(re_tile in todo){
  print(paste0("Processing tile: ",re_tile))
 
  
  ################################################################################
  ## Run the change detection
  # source("set_parameters_imad.R",echo=TRUE)
  # source("change_detection.R",echo=TRUE)
  # 
  # ################################################################################
  # ## Run the classification for the RapidEye image
  # 
  # outdir  <- paste0(rootdir,"results/",re_tile,"/re")
  # system(sprintf("mkdir %s",outdir ))
  # 
  # im_input <- re_input
  # 
  # source("set_parameters_classif.R",echo=TRUE)
  # source("prepare_training_data.R",echo=TRUE)
  # source("supervised_classification.R",echo=TRUE)
  # 
  # 
  # ################################################################################
  # ## Run the classification for the Sentinel image
  # 
  # outdir  <- paste0(rootdir,"/results/",re_tile,"/se")
  # system(sprintf("mkdir %s",outdir))
  # im_input <- se_input
  # 
  # 
  # source("set_parameters_classif.R",echo=TRUE)
  # source("prepare_training_data.R",echo=TRUE)
  # source("supervised_classification.R",echo=TRUE)
  # 

  ################################################################################
  ## Merge and finalize

  source("set_parameters_merge.R",echo=TRUE)
  #source("merge_datasets_and_stats.R",echo=TRUE)
  source("merge_for_shrub_change_product.R",echo=TRUE)
  
  
}

####################################################################################
#######          MERGE RESULTS FROM TILES AND COMPUTE ZONAL
####################################################################################
source("merge_tiles_and_zonal.R",echo=TRUE)

####################################################################################
#######          PROCESS GFC DATA AND COMPUTE ZONAL STATISTICS
####################################################################################
source("process_gfc_data.R",echo=TRUE)
