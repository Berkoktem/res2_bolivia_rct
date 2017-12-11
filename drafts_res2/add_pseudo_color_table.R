####################################################################################
####### Object:  Add pseudo color table to raster              
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/02/05                                         
####################################################################################


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
               paste0(workdir,"results_edited_20170613.tif"),
               paste0(workdir,"tmp_results_edited_20170613_pct.tif")
))

#### COMPRESS
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(workdir,"tmp_results_edited_20170613_pct.tif"),
               paste0(workdir,"results_edited_20170613_pct.tif")
))

#### REMOVE TMP
system(sprintf("rm %s",
               paste0(workdir,"tmp*.tif")
))
