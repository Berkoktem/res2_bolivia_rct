####################################################################################
####### Object:  Analyse results RE_S2 and GFC change detection in RCT              
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/06/13                                        
####################################################################################

####################################################################################
#######          SET PARAMETERS
####################################################################################
options(stringsAsFactors=FALSE)
library(ggplot2)
library(agricolae)
library(foreign)
# setwd("/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/bolivia/")
# setwd("C:/Users/dannunzio/Documents/countries/bolivia/")

####################################################################################
#######          READ DATA FILE
####################################################################################
df <- read.csv(paste0(rootdir,"stats_db_ecoregions_20170613.csv"))

names(df)
df <- df[df$cont_treat %in% c("cont","treat"),]

df$loss_00_10_ha <- rowSums(df[,paste0("loss_ha_ly_",1:10)])

####################################################################################
#######          CHECK DISTRIBUTION OF DATA FILE
####################################################################################
x1 <- table(df$cont_treat)

#### TOTAL AREA OF COMMUNITIES
x2 <- tapply(df$area_ha,df$cont_treat,FUN="sum")

#### TOTAL FOREST AREA WITHIN COMMUNITIES
x3 <- tapply(df$forest_ha_res2,df$cont_treat,FUN="sum")
x4 <- tapply(df$tc_2011_ha,df$cont_treat,FUN="sum")

#### TOTAL FOREST AREA LOSS WITHIN COMMUNITIES (RE_S2)
x5 <- tapply(df$loss_ha_res2,df$cont_treat,FUN="sum")

#### TOTAL RECENT FOREST AREA LOSS WITHIN COMMUNITIES (GFC)
x6 <- tapply(df$loss_11_14_ha,df$cont_treat,FUN="sum")


#### TOTAL PAST FOREST AREA LOSS WITHIN COMMUNITIES (GFC)
x7 <- tapply(df$loss_00_10_ha,df$cont_treat,FUN="sum")

res1 <- data.frame(cbind(x1,x2,x3,x4,x5,x6,x7))
names(res1) <- c("count","total_area","forest_area_res2","forest_area_gfc","loss_area_res2","recent_loss_area_gfc","past_loss_area_gfc")
res1
tapply(df$total_ha_ly-df$noloss_ha_ly,df$cont_treat,FUN="sum")

#### Size Distribution communities
ggplot(df,aes(x=area_ha,fill=cont_treat)) +
  geom_histogram(binwidth = 100) +
  labs(x = "Total area (ha)", 
       y = "Count", 
       title = "Distribution of areas of communities")


####################################################################################
#######          VARIOUS BAR GRAPHS OF LOSS vs. TREATMENT
####################################################################################
#### In terms of total loss area for RE_S2 (2011-2016)
ggplot(df,aes(cont_treat,loss_ha_res2)) +
  stat_summary(fun.y="sum",geom="bar")+
  labs(x = "", 
       y = "Loss area (ha)", 
       title = "Total loss with RE_S2 (2011-2016)")


#### In terms of total loss area for GFC (2011-2014)
ggplot(df,aes(cont_treat,loss_11_14_ha)) +
  stat_summary(fun.y="sum",geom="bar")+
  labs(x = "", 
       y = "Loss area (ha)", 
       title = "Total loss with GFC (2011-2014)")


#### In terms of average loss area for RE_S2 (2011-2016)
ggplot(df,aes(cont_treat,loss_ha_res2)) +
  stat_summary(fun.y="mean",geom="bar")+
  stat_summary(fun.data = mean_cl_normal, geom = "errorbar")+
  labs(x = "", 
       y = "Loss area (ha)", 
       title = "Average loss with RE_S2 (2011-2016)")


#### In terms of ofrest area for RE_S2 (2011-2016)
ggplot(df,aes(cont_treat,total_ha_res2)) +
  stat_summary(fun.y="sum",geom="bar")+
  #stat_summary(fun.data = mean_cl_normal, geom = "errorbar")+
  labs(x = "", 
       y = "Forest area (ha)", 
       title = "Forest with RE_S2 (2011-2016)")

#### In terms of average loss area for GFC (2011-2014)
ggplot(df,aes(cont_treat,loss_11_14_ha)) +
  stat_summary(fun.y="mean",geom="bar")+
  stat_summary(fun.data = mean_cl_normal, geom = "errorbar")+
  labs(x = "", 
       y = "Loss area (ha)", 
       title = "Average loss with GFC (2011-2014)")


#### Compute percentage of loss for both products
df$loss_pct_res2 <- df$loss_ha_res2  / df$forest_ha_res2
df$loss_pct_gfc  <- df$loss_11_14_ha / df$tc_2011_ha


#### In terms of Loss percentage (forest loss area / total forest area) for RE_S2 (2011-2016)
ggplot(df,aes(cont_treat,loss_pct_res2)) +
  stat_summary(fun.y="mean",geom="bar")+
  stat_summary(fun.data = mean_cl_normal, geom = "errorbar")+
  labs(x = "", 
       y = "Percentage loss (%)", 
       title = "Relative loss with RE_S2 (2011-2016)")


#### In terms of Loss percentage (forest loss area / total forest area) for GFC (2011-2014)
ggplot(df,aes(cont_treat,loss_pct_gfc)) +
  stat_summary(fun.y="mean",geom="bar")+
  stat_summary(fun.data = mean_cl_normal, geom = "errorbar")+
  labs(x = "", 
       y = "Percentage loss (%)", 
       title = "Relative loss with GFC (2011-2014)")


####################################################################################
#######          SCATTERPLOTS OF LOSS vs. TREATMENT
####################################################################################
#### Scatter plot of loss vs. forest area by treatment with RE_S2 (2011-2016)
ggplot(df,aes(forest_ha_res2,loss_ha_res2)) + 
  geom_point(aes(colour=cont_treat)) +
  labs(x = "Forest area (ha)", 
       y = "Loss area (ha)", 
       title = "Loss vs. Forest area with RE_S2 (2011-2016)")


#### Scatter plot of loss % vs. forest area by treatment with RE_S2 (2011-2016)
ggplot(df,aes(forest_ha_res2,loss_pct_res2)) + 
  geom_point(aes(colour=cont_treat)) +
  labs(x = "Forest area (ha)", 
       y = "Relative Loss (%)", 
       title = "Loss % vs. Forest area with RE_S2 (2011-2016)")


#### Scatter plot of loss vs. forest area by treatment GFC (2011-2014)
ggplot(df,aes(tc_2011_ha,loss_11_14_ha)) + 
  geom_point(aes(colour=cont_treat)) +
  labs(x = "Forest area (ha)", 
       y = "Loss area (ha)", 
       title = "Loss vs. Forest area with GFC (2011-2014)")



#### Scatter plot of loss % vs. forest area by treatment GFC (2011-2014)
ggplot(df,aes(tc_2011_ha,loss_pct_gfc)) + 
  geom_point(aes(colour=cont_treat)) +
  labs(x = "Forest area (ha)", 
       y = "Relative Loss (%)", 
       title = "Loss % vs. Forest area with GFC (2011-2014)")


####################################################################################
#######          SCATTERPLOT OF GFC LOSS vs. RE_S2 LOSS
####################################################################################
ggplot(df,aes(loss_11_14_ha,loss_ha_res2)) + 
  geom_point(aes(colour=cont_treat)) +
  labs(x = "GFC Loss (ha)", 
       y = "RE_S2 Loss (ha)", 
       title = "GFC vs. RE_S2 Loss Area")


####################################################################################
#######          ANOVA AND NON PARAMETRIC TESTS ON EFFECT
####################################################################################
names(df)
#### Anova, Tukey and Scheffe tests (forest loss by treatment) with RE_S2 (2011-2016)
myanova <- aov(loss_ha_res2 ~ cont_treat, data=df)
myanova

(tukey <- data.frame(TukeyHSD(myanova, "cont_treat")$cont_treat))
(scheffe<-scheffe.test(myanova, "cont_treat"))

#### Anova, Tukey and Scheffe tests (forest loss by treatment) with GFC (2011-2014)
myanova <- aov(loss_11_14_ha ~ cont_treat, data=df)
myanova

(tukey <- data.frame(TukeyHSD(myanova, "cont_treat")$cont_treat))
(scheffe<-scheffe.test(myanova, "cont_treat"))

#### Anova, Tukey and Scheffe tests (forest loss by treatment) with RE_S2 (2011-2016)
myanova <- aov(loss_pct_res2 ~ cont_treat, data=df)
myanova

(tukey <- data.frame(TukeyHSD(myanova, "cont_treat")$cont_treat))
(scheffe<-scheffe.test(myanova, "cont_treat"))

####################################################################################
#######          SCATTERPLOTS OF LOSS vs. TREATMENT for both openf and close f
####################################################################################
df$tot_loss_res2 <- df$loss_ha_res2 + df$openf_loss_ha_res2
df$tot_for_res2  <- df$forest_ha_res2 + df$openf_stable_ha_res2

#### Scatter plot of loss vs. forest area by treatment with RE_S2 (2011-2016)
ggplot(df,aes(tot_for_res2,tot_loss_res2)) + 
  geom_point(aes(colour=cont_treat)) +
  labs(x = "Forest area (ha)", 
       y = "Loss area (ha)", 
       title = "Loss vs. Forest area with RE_S2 (2011-2016)")


