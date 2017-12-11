####################################################################################
####### Object:  Combine community and ARA together            
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/09/19                                         
####################################################################################

setwd("/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/bolivia/gis_bolivia_rct/sql_joins/")

####################################################################################
#######  Change map
####################################################################################
setwd(rootdir)

dbf <- read.dbf(paste0(ara_dir,"ARA_2011_2014.dbf"))
table(dbf$level,dbf$year)

shp <- readOGR(paste0(ara_dir,"ARA_2011_2014.shp"),"ARA_2011_2014")
shp1 <- shp[shp$year != "2014-II",]
writeOGR(shp1,
         paste0(ara_dir,"ARA_2011_2014_up_to_2014_II.shp"),
         "ARA_2011_2014_up_to_2014_II",
         "ESRI Shapefile")

shp <- readOGR(paste0(ara_dir,"ARA_2011_2014_up_to_2014_II.shp"),
               "ARA_2011_2014_up_to_2014_II")

####################################################################################
#######  Rasterize community borders
system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a level",
               paste0(ara_dir,"ARA_2011_2014_up_to_2014_II.shp"),
               paste0(workdir,"results_edited_20170613.tif"),
               paste0(ara_dir,"ARA_2011_2014_by_level.tif")
))


system(sprintf("oft-zonal.py -um %s -i %s -o %s -a int_code",
               paste0(anmi_dir,"/","community_boundaries/","communities_UTM20_20170913.shp"),
               paste0(ara_dir,"ARA_2011_2014_by_level.tif"),
               paste0(zonal_dir,"zonal_ara_coverage_20170920.txt")
))

