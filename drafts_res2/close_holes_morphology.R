####################################################################################
####### Object:  core buffer periphery
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/02/13                                          
####################################################################################

class <- 1


# ################################################################################
# ## Extract binary product for losses
# ################################################################################
system(sprintf("gdal_calc.py -A %s --outfile=%s --calc=\"%s\"",
               paste0(rootdir,"results_merged/chdt_bolivia_rct_20170321.tif"),
               paste0(workdir,"tmp_binary_class_",class,".tif"),
               paste0("A==",class))
)

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(workdir,"tmp_binary_class_",class,".tif"),
               paste0(workdir,"binary_20170321_class_",class,".tif")
))

system(sprintf("rm %s",
               paste0(workdir,"tmp_binary_class_",class,".tif")
))


################################################################################
## Memory problems, subtiling (16GB RAM)
################################################################################
system(sprintf("oft-subset.pl %s %s %s",
               paste0(workdir,"binary_20170321_class_",class,".tif"),
               2,
               2))


subtile_dir <- paste0(workdir,"binary_20170321_class_",class,"_subset_tiles/")
list_files  <- list.files(subtile_dir,pattern=glob2rx("binary*.tif"))
file <- list_files[1]

################################################################################
## Morphological closing
################################################################################
for(file in list_files) {
  system(sprintf("otbcli_BinaryMorphologicalOperation -in %s -out %s -structype.ball.xradius %s -structype.ball.yradius %s -filter %s",
                 paste0(subtile_dir,file),
                 paste0(subtile_dir,"tmp_closing_",file),
                 size_morpho,
                 size_morpho,
                 "closing"
  ))

  system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
                 paste0(subtile_dir,"tmp_closing_",file),
                 paste0(subtile_dir,"closing_",file)
  ))

  system(sprintf("rm %s",
                 paste0(subtile_dir,"tmp_closing_",file)
                 ))
}

################################################################################
## Merge of subtiles for closing
################################################################################
system(sprintf("gdal_merge.py -o %s -v -ot byte -co COMPRESS=LZW %s",
               paste0(workdir,"tmp_closing.tif"),
               paste0(subtile_dir,"closing_binary*.tif")
)
)

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(workdir,"tmp_closing.tif"),
               paste0(workdir,"closing_20170321_class_",class,"_size_morpho_",size_morpho,".tif")
))

system(sprintf("rm %s",
               paste0(workdir,"tmp_closing.tif")
))


################################################################################
## Recombine masks 
################################################################################
system(sprintf("gdal_calc.py -A %s -B %s --outfile=%s --calc=\"%s\"",
               paste0(rootdir,"results_merged/chdt_bolivia_rct_20170321.tif"),
               paste0(workdir,"closing_20170321_class_",class,"_size_morpho_",size_morpho,".tif"),
               paste0(workdir,"tmp_chdt_bolivia_closed.tif"),
               paste0("(B==0)*A+(B==1)*",class)
))

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(workdir,"tmp_chdt_bolivia_closed.tif"),
               paste0(workdir,"chdt_bolivia_rct_20170321_closed_",size_morpho,".tif")
))


system(sprintf("rm %s",
               paste0(workdir,"tmp_chdt_bolivia_closed.tif")
))


(time <- Sys.time() - start)


