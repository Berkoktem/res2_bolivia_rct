dbf <- read.dbf("/media/dannunzio/lecrabe/bolivia_comunidades_s2/anmi_results/community_boundaries/border_community_utm.dbf")
df  <- read.csv("stats_db_20170413.csv")

#### Compute percentage of loss for both products
df$loss_pct_res2 <- df$loss_ha_res2  / df$forest_ha_res2
df$loss_pct_gfc  <- df$loss_11_14_ha / df$tc_2011_ha
df$tot_loss_res2 <- df$loss_ha_res2 + df$openf_loss_ha_res2
df$tot_for_res2  <- df$forest_ha_res2 + df$openf_stable_ha_res2


dbf$sort_id <- row(dbf)[,1]
head(dbf)
dbf$cod_otb
head(df,20)
dbf1 <- merge(dbf,df,by.x="NOMPRED",by.y="NOMPRED",all.x=TRUE)
dbf1 <- arrange(dbf1,sort_id)

write.dbf(dbf1,"/media/dannunzio/lecrabe/bolivia_comunidades_s2/anmi_results/results_shapefile/border_community_utm_.dbf")
df[df$cont_treat == "treat",][which.max(df[df$cont_treat == "treat",]$tot_loss_res2),]