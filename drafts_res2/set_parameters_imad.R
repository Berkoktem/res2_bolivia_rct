####################################################################################
####### Object:  Prepare names of all intermediate products                 
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/02/05                                        
####################################################################################

################################################################################
## Create an output master directory
tiledir  <- paste0(rootdir,"/results/",re_tile)
system(sprintf("mkdir %s",tiledir))

################################################################################
## Create an output directory for the change products
imaddir  <- paste0(rootdir,"results/",re_tile,"/imad")
system(sprintf("mkdir %s",imaddir))

################################################################################
## Name of inputs
re_path  <- list.files(path=all_re_dir,pattern=paste0(re_tile,"_2011"))
re_file  <- paste0(all_re_dir,re_path,"/img/raw/",re_path,".tif")
se_file  <- paste0(all_s2_dir,"s2_",re_tile,".tif")

imad     <- paste0(imaddir,"/tile_",re_tile,"_imad.tif")   # imad output name
noch_msk <- paste0(imaddir,"/tile_",re_tile,"_no_change_mask.tif")   # no change mask
chdt_msk <- paste0(imaddir,"/tile_",re_tile,"_chdt.tif")   # thresholded imad product

imad_mm  <- paste0(imaddir,"/tile_",re_tile,"imad_minmax.txt") # imad min max values
imad_info<- paste0(imaddir,"/tile_",re_tile,"imad_info.txt")   # imad gdalinfo values

norm_imad<-paste0(imaddir,"/tile_",re_tile,"_normimad.tif")

re_input <- paste0(imaddir,"/tile_",re_tile,"_re.tif") # name of band-harmonized and co-mask RapidEye imagery
se_input <- paste0(imaddir,"/tile_",re_tile,"_se.tif") # name of band-harmonized and co-mask Sentinel imagery

