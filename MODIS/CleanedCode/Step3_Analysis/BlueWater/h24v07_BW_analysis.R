library(dlm)
library(raster)
library(zyp)

##Read source file##
source("/media/functions/dlm2covarintercept_15FEB2015.R")

#### Set working directory ####
setwd("/media/MOD16_A2/h24v07/")

##Load saved R objects##
load("ET_rain_BW_h24v07.RData")

### running trend analysis using sen's slope on blue water ###
sen_bw.h24v07<-zyp.trend.dataframe(blueWater.h24v07, metadata.cols=1, method=c("yuepilon"),
                                   conf.intervals=TRUE, preserve.range.for.sig.test=TRUE)
summary(sen_bw.h24v07)
h24v07_bw_yearlytrendp <- setValues(blank, sen_bw.h24v07$trendp)
h24v07_bw_yearlysig<-setValues(blank,sen_bw.h24v07$sig)
h24v07_bw_yearlysig <- reclassify(h24v07_bw_yearlysig, c(-Inf,0.1,1, 0.1,Inf,NA))
h24v07_bw_yearlytrendp_sig<-(h24v07_bw_yearlytrendp*h24v07_bw_yearlysig)
#plot(h24v07_bw_yearlytrendp_sig)

############3 Running DLM using TRMM and LST as covariates ##############

intslp.BW.h24v07<-dlmtwocovar(blueWater.h24v07,rain.h24v07,degC.h24v07)
dlm.BW.h24v07.int<-intslp.BW.h24v07[,1:(length(intslp.BW.h24v07)/3)]

### running trend analysis using sen's slope ###

sen_dlm_BW.h24v07<-zyp.trend.dataframe(dlm.BW.h24v07.int, metadata.cols=0, method=c("yuepilon"),
                                       conf.intervals=TRUE, preserve.range.for.sig.test=TRUE)

h24v07_dlm_BWtrendp <- setValues(blank, sen_dlm_BW.h24v07$trendp)
h24v07_dlm_BWsig<-setValues(blank,sen_dlm_BW.h24v07$sig)
h24v07_dlm_BWsig <- reclassify(h24v07_dlm_BWsig, c(-Inf,0.1,1, 0.1,Inf,NA))
h24v07_bw_yearlytrendpDLM_sig<-(h24v07_dlm_BWtrendp*h24v07_dlm_BWsig)
plot(h24v07_bw_yearlytrendpDLM_sig)

### Writing results to raster ###
setwd("/media/MOD16_A2/results")
writeRaster(h24v07_bw_yearlytrendp_sig,"h24v07_bw_yearlytrendp_sig.grd", overwrite=T)
writeRaster(h24v07_bw_yearlytrendp,"h24v07_bw_yearlytrendp.grd", overwrite=T)
writeRaster(h24v07_bw_yearlytrendpDLM_sig,"h24v07_bw_yearlytrendpDLM_sig.grd",overwrite=T)
writeRaster(h24v07_dlm_BWtrendp,"h24v07_bw_yearlytrendpDLM.grd",overwrite=T)

### Save data ###
setwd("/media/MOD16_A2/h24v07/")
save(list = ls(all = TRUE), file = "ResultsBWh24v07.RData")
rm(list=ls())
print("Finished processing tile h24v07")
#q("no")
