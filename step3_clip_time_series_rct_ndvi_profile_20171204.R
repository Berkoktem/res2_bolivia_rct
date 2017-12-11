####################################################################################################
####################################################################################################
## Clip time series to desired boxes: Landsat time series, Sentinel, NBR trend and Original Map
## Contact remi.dannunzio@fao.org
####################################################################################################
####################################################################################################

options(stringsAsFactors=FALSE)
library(Hmisc)
library(sp)
library(rgdal)
library(raster)
library(plyr)
library(foreign)
library(dplyr)
library(spatialEco)
library(rasterVis)



##########################################################################################################################################################################
################# Directory and FILE : ADAPT TO YOUR CONFIGURATION
##########################################################################################################################################################################


#### Name of the harddisk where you have your data
rootdir  <- "d:/bolivia_comunidades_s2/"

setwd(rootdir)

#### Name of the directory where your Landsat data is
lsat_dir <- paste(rootdir,"time_series/landsat_gee/",sep="")

#### Name of the directory where your Sentinel data is
stnl_dir <- paste(rootdir,"sentinel_2016/s2_tiled_re_aws/",sep="")

#### Name of the directory where rapideye 2011 data is
re11_dir <- paste(rootdir,"time_series/rapideye_2011/",sep="")

#### Name of the directory where rapideye 2011 data is
re10_dir <- paste(rootdir,"time_series/rapideye_2010/",sep="")

#### Name of the directory where your data will be stored in output
dest_dir <- paste(rootdir,"time_series/clip_time_series/",sep="")

#### Path to your file point and set the parameters
response <- "sae_design_defor_map_gfc16_th30_utm/pts_bolivia_contracts_gfc_th30_CE_2017-12-04.csv"

################## Read points from Design_App
pts <- read.csv(response)
head(pts)

map_code <- "map_class"
point_id <- "id"
xcoord   <- "XCoordinate"
ycoord   <- "YCoordinate"

table(pts[,map_code])
##########################################################################################################################################################################
################## SCRIPT AUTOMATICALLY RUNS FROM HERE
##########################################################################################################################################################################



################# Create spatial point file 
pt_df_geo <- SpatialPointsDataFrame(
  coords = pts[,c(xcoord,ycoord)],
  data   = data.frame(pts[,c(point_id,map_code)]),
  proj4string=CRS("+init=epsg:4326")
)


################ Create the index of the Landsat tiles
list_lsat <- list.files(lsat_dir,pattern="clip2010")
lp<-list()

for(file in list_lsat){
  raster <- raster(paste(lsat_dir,file,sep=""))
  
  e<-extent(raster)
  
  poly <- Polygons(list(Polygon(cbind(
    c(e@xmin,e@xmin,e@xmax,e@xmax,e@xmin),
    c(e@ymin,e@ymax,e@ymax,e@ymin,e@ymin))
  )),file)
  lp <- append(lp,list(poly))
}

## Transform the list into a SPDF
lsat_idx <-SpatialPolygonsDataFrame(
  SpatialPolygons(lp,1:length(lp)), 
  data.frame(list_lsat), 
  match.ID = F
)

names(lsat_idx@data) <- "bb"
lsat_idx@data$bb <- substr(lsat_idx@data$bb,21,(nchar(lsat_idx@data$bb)-4))
lsat_idx@data

################ Create the index of the Sentinel tiles
list_s2 <- list.files(stnl_dir,pattern=glob2rx("s2_*.tif"))
lp<-list()

for(file in list_s2){
  raster <- raster(paste(stnl_dir,file,sep=""))
  
  e<-extent(raster)
  
  poly <- Polygons(list(Polygon(cbind(
    c(e@xmin,e@xmin,e@xmax,e@xmax,e@xmin),
    c(e@ymin,e@ymax,e@ymax,e@ymin,e@ymin))
  )),file)
  lp <- append(lp,list(poly))
}

## Transform the list into a SPDF
stnl_idx <-SpatialPolygonsDataFrame(
  SpatialPolygons(lp,1:length(lp)), 
  data.frame(list_s2), 
  match.ID = F
)

names(stnl_idx@data) <- "bb"
stnl_idx@data$bb <- substr(stnl_idx@data$bb,4,(nchar(stnl_idx@data$bb)-4))
stnl_idx@data

################ Create the index of the rapideye 2010 tiles
list_re10 <- list.files(re10_dir,pattern=glob2rx("*.tif"))
lp<-list()

for(file in list_re10){
  raster <- raster(paste(re10_dir,file,sep=""))
  
  e<-extent(raster)
  
  poly <- Polygons(list(Polygon(cbind(
    c(e@xmin,e@xmin,e@xmax,e@xmax,e@xmin),
    c(e@ymin,e@ymax,e@ymax,e@ymin,e@ymin))
  )),file)
  lp <- append(lp,list(poly))
}

## Transform the list into a SPDF
re10_idx <-SpatialPolygonsDataFrame(
  SpatialPolygons(lp,1:length(lp)), 
  data.frame(list_re10), 
  match.ID = F
)

names(re10_idx@data) <- "bb"
re10_idx@data$bb <- substr(re10_idx@data$bb,6,(nchar(re10_idx@data$bb)-7))
re10_idx@data


################ Create the index of the rapideye 2011 tiles
list_re11 <- list.files(re11_dir,pattern=glob2rx("*.tif"))
lp<-list()

for(file in list_re11){
  raster <- raster(paste(re11_dir,file,sep=""))
  
  e<-extent(raster)
  
  poly <- Polygons(list(Polygon(cbind(
    c(e@xmin,e@xmin,e@xmax,e@xmax,e@xmin),
    c(e@ymin,e@ymax,e@ymax,e@ymin,e@ymin))
  )),file)
  lp <- append(lp,list(poly))
}

## Transform the list into a SPDF
re11_idx <-SpatialPolygonsDataFrame(
  SpatialPolygons(lp,1:length(lp)), 
  data.frame(list_re11), 
  match.ID = F
)

names(re11_idx@data) <- "bb"
re11_idx@data$bb <- substr(re11_idx@data$bb,6,(nchar(re11_idx@data$bb)-7))
re11_idx@data


################# Project both into Lat-Lon EPSG:4326
proj4string(pt_df_geo) <- proj4string(lsat_idx) <- CRS("+init=epsg:4326")
proj4string(stnl_idx) <- proj4string(re11_idx) <- proj4string(re10_idx)  <- CRS("+init=epsg:32720")

pt_df_utm <- spTransform(pt_df_geo,CRS("+init=epsg:32720"))

################# Intersect points with index of imagery and append ID's of imagery to data.frame
pts_lsat <- over(pt_df_geo,lsat_idx)
pts_stnl <- over(pt_df_utm,stnl_idx)
pts_re10 <- over(pt_df_utm,re10_idx)
pts_re11 <- over(pt_df_utm,re11_idx)

pts<-cbind(pts,pts_lsat$bb)
pts<-cbind(pts,pts_stnl$bb)
pts<-cbind(pts,pts_re10$bb)
pts<-cbind(pts,pts_re11$bb)

################# Create the outside boundaries box (1km // twice 500m from center of box)
lp<-list()
ysize <- 500/111321

## Loop through all points
for(i in 1:nrow(pts)){
  ymin <- pts[i,ycoord]-ysize
  ymax <- pts[i,ycoord]+ysize
  xmin <- pts[i,xcoord]-ysize*cos(pts[1,ycoord]*pi/180)
  xmax <- pts[i,xcoord]+ysize*cos(pts[1,ycoord]*pi/180)
  
  p  <- Polygon(cbind(c(xmin,xmin,xmax,xmax,xmin),c(ymin,ymax,ymax,ymin,ymin)))
  ps <- Polygons(list(p), pts[i,1])
  lp <- append(lp,list(ps))
}

## Transform the list into a SPDF
outbox<-SpatialPolygonsDataFrame(
  SpatialPolygons(lp,1:nrow(pts)), 
  pts[,c(map_code,point_id,xcoord,ycoord)], 
  match.ID = F
  )


################# Create the one pixel box 30m 
lp<-list()
ysize <- 15/111321

## Loop through all points
for(i in 1:nrow(pts)){
  ymin <- pts[i,ycoord]-ysize
  ymax <- pts[i,ycoord]+ysize
  xmin <- pts[i,xcoord]-ysize*cos(pts[1,ycoord]*pi/180)
  xmax <- pts[i,xcoord]+ysize*cos(pts[1,ycoord]*pi/180)
  
  p  <- Polygon(cbind(c(xmin,xmin,xmax,xmax,xmin),c(ymin,ymax,ymax,ymin,ymin)))
  ps <- Polygons(list(p), pts[i,1])
  lp <- append(lp,list(ps))
}

## Transform the list into a SPDF
inbox<-SpatialPolygonsDataFrame(
  SpatialPolygons(lp,1:nrow(pts)), 
  pts[,c(map_code,point_id,xcoord,ycoord)], 
  match.ID = F
)


proj4string(inbox) <- proj4string(outbox) <- CRS("+init=epsg:4326")

inbox_utm <- spTransform(inbox,CRS("+init=epsg:32720"))
outbox_utm <- spTransform(outbox,CRS("+init=epsg:32720"))

#####################################################################################
#####################################################################################
#####################################################################################

################# Loop through the IDs
#
the_id = "241"
tail(pts)
list_ids <- pts[,point_id]
listdone <- data.frame(strsplit(list.files("clip_time_series/"),"_"))[2,]
listodo <- list_ids[!(list_ids %in% listdone)]

######################################################################################################

for(the_id in listodo){
  #           dev.off()
      (the_pt <- pts[pts[,point_id]==the_id,])
      
      ####################################################################
      ##### Delimitations of the plot in geographic coordinates
      one_poly <- outbox[outbox@data[,point_id]==the_id,]
      in_poly  <-   inbox[inbox@data[,point_id]==the_id,]
      
      margins <- extent(
        one_poly@bbox["x","min"]-50/111321,
        one_poly@bbox["x","max"]+50/111321,
        one_poly@bbox["y","min"]-50/111321,
        one_poly@bbox["y","max"]+50/111321)
      
      ####################################################################
      ##### Delimitations of the plot in UTM coordinates
      one_poly_utm <- outbox_utm[outbox_utm@data[,point_id]==the_id,]
      in_poly_utm  <-   inbox_utm[inbox_utm@data[,point_id]==the_id,]
      
      margins_utm <- extent(
        one_poly_utm@bbox["x","min"]-50,
        one_poly_utm@bbox["x","max"]+50,
        one_poly_utm@bbox["y","min"]-50,
        one_poly_utm@bbox["y","max"]+50)
      
      ####################################################################
      ################# Find the corresponding indexes
      lsat_bbox <- the_pt[,"pts_lsat$bb"]
      stnl_bbox <- the_pt[,"pts_stnl$bb"]
      re10_bbox <- the_pt[,"pts_re10$bb"]
      re11_bbox <- the_pt[,"pts_re11$bb"]
        
      ####################################################################
      ################# Open the image output file
      out_name <- paste(dest_dir,"pt_",the_id,"_class_",pts[pts[,point_id]==the_id,map_code],".png",sep="")
      png(file=out_name,width=2400,height=1200)
                
                ################# Set the layout
                #dev.off()
                ## The export image will be in a 3 (height) x 5 (width) grid box
                par(mfrow = c(3,6))
                par(mar=c(1,0,1,0))
                
                ndvi_trend <- data.frame(matrix(nrow=0,ncol=2))
                names(ndvi_trend) <- c("year","mean")
                i <- 1

                ####################################################################
                ################# Clip the landsat time series
                for(year in c(2000:2009)){
                      print(year)
                      tryCatch({
                        lsat <- brick(paste(lsat_dir,"median_hul_clip",year,"_",lsat_bbox,".tif",sep=""))
                        lsat_clip<-crop(lsat,one_poly)

                        swir <- raster(lsat_clip,4)
                        nir  <- raster(lsat_clip,3)
                        red  <- raster(lsat_clip,2)
                        ndvi <- (nir-red)/(nir+red)

                        ndvi_trend[i,]$year <- year
                        ndvi_trend[i,]$mean <- cellStats(crop(ndvi,in_poly),stat='mean')
                        i <- i + 1

                        plot(margins,axes=F,xlab="",ylab="")
                        stack <- stack(swir,nir,red)

                        plotRGB(stack,stretch="hist",add=T)

                        lines(in_poly,col="red",lwd=2)
                        title(main=paste("landsat_",year,sep=""),font.main=1200)
                        },
                        error=function(e){cat("Configuration impossible \n")})
                    }


                ####################################################################
                ################# Clip the rapideye 2010 tile 
                plot(margins_utm,axes=F,xlab="",ylab="")
                the_pt
                tryCatch({
                  re10 <- brick(paste(re10_dir,"tile_",re10_bbox,"_re.tif",sep=""))
                  re10_clip<-crop(re10,one_poly_utm)
                  
                  blu <- raster(re10_clip,1)
                  grn <- raster(re10_clip,2)
                  red <- raster(re10_clip,3)
                  nir <- raster(re10_clip,5)
                  
                  ndvi <- (nir-red)/(nir+red)
                  
                  ndvi_trend[i,]$year <- 2010
                  ndvi_trend[i,]$mean <- cellStats(crop(ndvi,in_poly_utm),stat='mean')
                  i <- i + 1
                  
                  R <- red
                  G <- grn
                  B <- blu
                  
                  stackNat <- stack(R,G,B)
                  plotRGB(stackNat,stretch="hist",add=T)
                  
                  
                },error=function(e){cat("Configuration impossible \n")})
                lines(in_poly_utm,col="red",lwd=1)

                
                title(main="rapideye_2010",font.main=200)
                
                
                ####################################################################
                ################# Clip the rapideye 2011 tile 
                plot(margins_utm,axes=F,xlab="",ylab="")
                the_pt
                tryCatch({
                  re11 <- brick(paste(re11_dir,"tile_",re11_bbox,"_re.tif",sep=""))
                  re11_clip<-crop(re11,one_poly_utm)
                  
                  blu <- raster(re11_clip,1)
                  grn <- raster(re11_clip,2)
                  red <- raster(re11_clip,3)
                  nir <- raster(re11_clip,4)
                  
                  ndvi <- (nir-red)/(nir+red)
                  
                  ndvi_trend[i,]$year <- 2011
                  ndvi_trend[i,]$mean <- cellStats(crop(ndvi,in_poly_utm),stat='mean')
                  i <- i + 1
                  
                  R <- red
                  G <- grn
                  B <- blu
                  
                  stackNat <- stack(R,G,B)
                  plotRGB(stackNat,stretch="hist",add=T)
                  
                },error=function(e){cat("Configuration impossible \n")})
                lines(in_poly_utm,col="red",lwd=1)
                #plot(in_poly,add=T,col="red")
                
                title(main="rapideye_2011",font.main=200)
                
                
                ####################################################################
                ################# Clip the landsat time series
                for(year in c(2012:2015)){
                  print(year)
                  tryCatch({
                    lsat <- brick(paste(lsat_dir,"median_hul_clip",year,"_",lsat_bbox,".tif",sep=""))
                    lsat_clip<-crop(lsat,one_poly)
                    
                    swir <- raster(lsat_clip,4)
                    nir  <- raster(lsat_clip,3)
                    red  <- raster(lsat_clip,2)
                    ndvi <- (nir-red)/(nir+red)
                    
                    ndvi_trend[i,]$year <- year 
                    ndvi_trend[i,]$mean <- cellStats(crop(ndvi,in_poly),stat='mean')
                    i <- i + 1
                    
                    plot(margins,axes=F,xlab="",ylab="")
                    stack <- stack(swir,nir,red)
                    
                    plotRGB(stack,stretch="hist",add=T)
                    
                    lines(in_poly,col="red",lwd=2)
                    title(main=paste("landsat_",year,sep=""),font.main=1200)
                    
                  },
                  error=function(e){cat("Configuration impossible \n")})
                }
                
                ####################################################################
                ################# Clip the sentinel tile 
                plot(margins_utm,axes=F,xlab="",ylab="")
                the_pt
                tryCatch({
                  stnl <- brick(paste(stnl_dir,"s2_",stnl_bbox,".tif",sep=""))
                  stnl_clip<-crop(stnl,one_poly_utm)
                  
                  blu <- raster(stnl_clip,1)
                  grn <- raster(stnl_clip,2)
                  red <- raster(stnl_clip,3)
                  nir <- raster(stnl_clip,4)
                  
                  ndvi <- (nir-red)/(nir+red)
                  ndvi_trend[i,]$year <- 2016
                  ndvi_trend[i,]$mean <- cellStats(crop(ndvi,in_poly_utm),stat='mean')
                  i <- i + 1
                  
                  R <- red
                  G <- grn
                  B <- blu
                  
                  stackNat <- stack(R,G,B)
                  plotRGB(stackNat,stretch="hist",add=T)
                
                },error=function(e){cat("Configuration impossible \n")})
                lines(in_poly_utm,col="red",lwd=1)
                #plot(in_poly,add=T,col="red")
                
                title(main="sentinel_2016",font.main=200)
                
                
                
                ####################################################################
                ################# function to all pixel stack 
                
                par(mar=c(2,2,2,2))
                plot(ndvi_trend,
                     # yaxt='n',
                     # xaxt='n',
                     xlab="year",
                     ylab="",
                     ylim=c(0,1)
                )
                
                title(main="mean ndvi",font.main=200)
                
                ####################################################################
                ### Close the image file
                dev.off()
                
                
      ####################################################################
      ### End the points loop
      }


