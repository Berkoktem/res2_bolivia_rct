####################################################################################
####### Object:  Merge results from classification and assign change value
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/11/08                                          
####################################################################################

merge_time <- Sys.time()

################################################################################
## Clump the results of the Sentinel classification
# system(sprintf("oft-clump -i %s -o %s -um %s",se_file,paste0(mergedir,"/","tmp_sel_seg_id.tif"),se_file))
# system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",paste0(mergedir,"/","tmp_sel_seg_id.tif"),segs_id))
# system(sprintf(paste0("rm ",mergedir,"/","tmp_*.*")))
# 
# ################################################################################
# ## Compute Sentinel classification value
# system(sprintf("oft-stat -i %s -o %s -um %s -nostd",se_file,se_cl_st,segs_id))
# 
# ################################################################################
# ## Compute Rapideye classification value
# system(sprintf("oft-his -i %s -o %s -um %s -maxval 42",re_file,re_cl_st,segs_id))
# 
# ################################################################################
# ## Compute IMAD change values
# system(sprintf("oft-stat -i %s -o %s -um %s -nostd",imad,im_cl_st,segs_id))

################################################################################
## Load PBS legend
legend_pbs <- data.frame(cbind(
  c("clouds","snow_temp","snow",
    "water","water","water_dry","water","water","water",
    "forest_evg_dense","forest_evg_dense","forest_evg_dense","shrub_evg_dense",
    "grass_evg","forest_evg_open","shrub_evg",
    "empty","empty","empty",
    "forest_deciduous_closed_humid","cultivated_and_forest_deciduous_open_humid",
    "empty","empty","empty",
    "forest_deciduous_closed_dry","forest_deciduous_open_dry",
    "agriculture","shrub_deciduous_dense_humid","shrub_deciduous","shrub_deciduous_open",
    "shrubs_herbaceous","grass",
    "empty",
    "soil_grass","soil","soil_dark",
    "empty","empty","empty",
    "shadow_vegetation","soil_dark","shadow_soil"),
  1:42))
names(legend_pbs) <- c("pbs_class","se_class")


################################################################################
## Create one data file with all info
df_se <- read.table(se_cl_st)
df_re <- read.table(re_cl_st)
df_im <- read.table(im_cl_st)

names(df_se) <- c("sg_id","sg_sz","se_class")
names(df_im) <- c("sg_id","sg_sz","imad")
names(df_re) <- c("sg_id","total","no_data",legend_pbs$pbs_class)

head(df_se)
head(df_re)
head(df_im)

summary(df_re$total - rowSums(df_re[,3:45]))

df <- df_se

df$sortid <- row(df)[,1]

df <- merge(df,df_im)
df <- merge(df,df_re)
df <- merge(df,legend_pbs)

################################################################################
## Determine criterias for change 

## Take out the columns that don't have any pixels coded
df1 <- df[,colSums(df[,!(names(df) %in% "pbs_class")]) != 0]

## Check dataset
# head(df1)
# colSums(df1[,!(names(df1) %in% "pbs_class")])/10000
table(df1$se_class)

## Create a new reclass column: 1==forest loss, 2==forest stable, 3==the rest, 4 == water, 5 == shrub loss, 6 = shrub stable
df1$recl <- 3

tryCatch({
  df1[
    df1$sg_sz > 10 & #size is bigger than 10 pixels (1 pixel = 5m*5m = 25 m2)
      df1$pbs_class %in% legend_pbs[grep(pattern="forest",legend_pbs$pbs_class),]$pbs_class & # the Sentinel classification says "Forest"
      rowSums(df1[,grep(pattern = "forest",names(df1))]) > 5 , # The RapidEye classification says "Forest"
    ]$recl <- 2
}, error=function(e){cat("Configuration impossible \n")}
)


tryCatch({
  df1[
    df1$sg_sz > 36 & #size is bigger than 36 pixels (1 pixel = 5m*5m = 25 m2)
      !(df1$pbs_class %in% legend_pbs[grep(pattern="forest",legend_pbs$pbs_class),]$pbs_class) & # the Sentinel classification says "Not Forest"
      rowSums(df1[,grep(pattern = "forest",names(df1))]) > (0.75*df1$sg_sz) & # The RapidEye classification says "Forest" for more than 70% of the segment
      df1$imad > 1000, #IMAD indicates some change is occuring
    ]$recl <- 1
}, error=function(e){cat("Configuration impossible \n")}
)


tryCatch({
  df1[
    df1$sg_sz > 10 & #size is bigger than 10 pixels (1 pixel = 5m*5m = 25 m2)
      df1$pbs_class %in% legend_pbs[grep(pattern="shrub",legend_pbs$pbs_class),]$pbs_class & # the Sentinel classification says "shrub"
      rowSums(df1[,grep(pattern = "shrub",names(df1))]) > 5 , # The RapidEye classification says "shrub"
    ]$recl <- 6
}, error=function(e){cat("Configuration impossible \n")}
)

tryCatch({
  df1[
    df1$sg_sz > 36 & #size is bigger than 36 pixels (1 pixel = 5m*5m = 25 m2)
      !(df1$pbs_class %in% legend_pbs[c(grep(pattern="shrub",legend_pbs$pbs_class),grep(pattern="forest",legend_pbs$pbs_class)),]$pbs_class) & # the Sentinel classification says "Not Forest"
      rowSums(df1[,grep(pattern = "shrub",names(df1))]) > (0.75*df1$sg_sz) & # The RapidEye classification says "Forest" for more than 70% of the segment
      df1$imad > 1000, #IMAD indicates some change is occuring
    ]$recl <- 5
}, error=function(e){cat("Configuration impossible \n")}
)


tryCatch({
  df1[
    df1$pbs_class %in% 
      legend_pbs[grep(pattern="water",
                      legend_pbs$pbs_class)
                 ,]$pbs_class
    |
      rowSums(df1[,grep(pattern = "water",names(df1))]) > (0.75*df1$sg_sz)   
    ,]$recl <- 4
}, error=function(e){cat("Configuration impossible \n")}
) 


## Resort in the same order as it was when read
df2 <- arrange(df1,sortid)
table(df2$recl)

## Export as data table
write.table(file=reclass_shrub,df2[,c("sg_id","recl")],sep=" ",quote=FALSE, col.names=FALSE,row.names=FALSE)

## Reclass the raster with the change values
system(sprintf("(echo %s; echo 1; echo 1; echo 2; echo 0) | oft-reclass -oi  %s %s",
               reclass_shrub,paste0(mergedir,"/","tmp_reclass.tif"),segs_id))

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(mergedir,"/","tmp_reclass.tif"),
               chg_class_shrub))

system(sprintf(paste0("rm ",mergedir,"/","tmp*.tif")))

#rm(list=ls(pattern="df"))
