####################################################################################
####### Object:  Run change detection between two dates             
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/11/06                                           
####################################################################################
tile_start_time <- Sys.time()

####################################################################################################################
########### Run the IMAD based change detection
####################################################################################################################
## Select the right bands of image 1 and mask with image 2
system(sprintf("(echo 4; echo \"#1\"; echo \"#2\"; echo \"#3\"; echo \"#5\") | oft-calc -ot UInt16 -um %s %s %s",se_file,re_file,paste0(imaddir,"/","tmp_re4b.tif")))

## Select the right bands of image 2 and mask with image 1
system(sprintf("(echo 4; echo \"#1\"; echo \"#2\"; echo \"#3\"; echo \"#4\") | oft-calc -ot UInt16 -um %s %s %s",re_file,se_file,paste0(imaddir,"/","tmp_se4b.tif")))

## Perform change detection
system(sprintf("bash oft-chdet.bash %s %s %s 0",paste0(imaddir,"/","tmp_re4b.tif"),paste0(imaddir,"/","tmp_se4b.tif"),paste0(imaddir,"/","tmp_chdet.tif")))

## Compress results
system(sprintf("gdal_translate -ot UInt16 -co COMPRESS=LZW %s %s",paste0(imaddir,"/","imad-tmp_chdet.tif"),imad))
system(sprintf("gdal_translate -ot UInt16 -co COMPRESS=LZW %s %s",paste0(imaddir,"/","tmp_re4b.tif"),re_input))
system(sprintf("gdal_translate -ot UInt16 -co COMPRESS=LZW %s %s",paste0(imaddir,"/","tmp_se4b.tif"),se_input))


# ################################################################################
# ## Thresholding of the imad detection (1 is stable, 2 is change, 0 is no data)
# system(sprintf("gdal_calc.py -A %s --outfile=%s --calc=\"%s\"",
#                imad,
#                paste0(imaddir,"/","tmp_chdet.tif"),
#                paste0("(A>0)*(A<",thresh_imad,")*1+(A>(",thresh_imad,"-1))*2")
#                )
# )
# system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",paste0(imaddir,"/","tmp_chdet.tif"),chdt_msk))
# system(sprintf(paste0("rm ",imaddir,"/","*tmp*.tif")))

# ################################################################################
# ## Compute values of the imaf product
# system(sprintf("oft-mm -um %s %s > %s",imad,imad,imad_mm))
# system(sprintf("gdalinfo -stats %s > %s",imad,imad_info))
# 
# nbands <- nbands(raster(imad))
# 
# mm_info <- readLines(imad_mm)
# info    <- readLines(paste0(imad_info))
#                      
# stat_info <- data.frame(t(data.frame(strsplit(info[grep(info,pattern="Minimum=")],split=","))))
# 
# true_min <- as.numeric(unlist(strsplit(mm_info[grep(mm_info,pattern=" min =")],split=" = "))[2*(1:nbands)])
# true_max <- as.numeric(unlist(strsplit(mm_info[grep(mm_info,pattern=" max =")],split=" = "))[2*(1:nbands)])
# stat_max <- as.numeric(gsub(pattern = "Maximum=",replacement="",stat_info[,2]))
# stat_mean<- as.numeric(gsub(pattern = "Mean=",replacement="",stat_info[,3]))
# stat_sd  <- as.numeric(gsub(pattern = "StdDev=",replacement="",stat_info[,4]))
# 
# stats <- data.frame(cbind(true_min,true_max,stat_max,stat_mean,stat_sd) )
# stats <- round(stats,digits=0)



################################################################################
## Normalize to 0-100 the values of the imad
system(sprintf(
  "(echo 1; echo \"#1 65535 / 100 *\") | oft-calc -ot Byte %s %s",
  imad,
  paste0(imaddir,"/","tmp_norm_imad.tif")
))

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",paste0(imaddir,"/","tmp_norm_imad.tif"),norm_imad))
system(sprintf(paste0("rm ",imaddir,"/","tmp*.tif")))



################################################################################
## Create a no change mask
system(sprintf("gdal_calc.py -A %s  --outfile=%s --calc=\"%s\"",
               imad,
                              paste0(imaddir,"/","tmp_noch.tif"),
               paste0("(A<1000)")
)
)

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",paste0(imaddir,"/","tmp_noch.tif"),noch_msk))
system(sprintf(paste0("rm ",imaddir,"/","tmp*.tif")))


(time <- Sys.time() - tile_start_time)
