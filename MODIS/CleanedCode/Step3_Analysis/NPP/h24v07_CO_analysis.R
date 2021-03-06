library(dlm)
library(raster)
library(zyp)

##locate source files to run DLM##
source("/media/functions/dlmonecovar.R")
setwd("/media/MOD17_A2/h24v07/")

##load R objects##
load("NPP_h24v07.RData")

### running dlm ###
intslp.npp.h24v07<-dlmonecovar(npp.h24v07,degC.h24v07)
npp.h24v07.yearly.int<-intslp.npp.h24v07[,1:(length(intslp.npp.h24v07)/2)]
summary(npp.h24v07.yearly.int)
### running trend analysis using sen's slope ###
sen_npp.h24v07<-zyp.trend.dataframe(npp.h24v07.yearly.int, metadata.cols=0, method=c("yuepilon"),
                                    conf.intervals=TRUE, preserve.range.for.sig.test=TRUE)
h24v07npp_yearly_trendp <- setValues(blank, sen_npp.h24v07$trendp)
h24v07npp_yearly_sig<-setValues(blank,sen_npp.h24v07$sig)
h24v07npp_yearly_sig <- reclassify(h24v07npp_yearly_sig, c(-Inf,0.1,1, 0.1,Inf,NA))
h24v07npp_yearly_trendp_sig<-(h24v07npp_yearly_trendp*h24v07npp_yearly_sig)


##################raw npp######################

sen_npp.h24v07.raw<-zyp.trend.dataframe(npp.h24v07, metadata.cols=0, method=c("yuepilon"),
                                        conf.intervals=TRUE, preserve.range.for.sig.test=TRUE)
h24v07npp.raw.trend <- setValues(blank, sen_npp.h24v07.raw$trendp)
h24v07npp_raw_sig<-setValues(blank,sen_npp.h24v07.raw$sig)
h24v07npp.raw.trend.sig<-(h24v07npp.raw.trend*h24v07npp_raw_sig)

### Writing results to raster ###
setwd("/media/MOD17_A2/results")

writeRaster(h24v07npp_yearly_trendp.sig, "h24v07npp_yearly_trendp_sig.grd", overwrite=T)
writeRaster(h24v07npp_yearly_trendp, "h24v07npp_yearly_trendp.grd", overwrite=T)
writeRaster(h24v07npp.raw.trend.sig, "h24v07npp.raw.trend.sig.grd", overwrite=T)
writeRaster(h24v07npp.raw.trend, "h24v07npp.raw.trend.grd", overwrite=T)

### Save data ###
setwd("/media/MOD17_A2/h24v07/")
save.image(file = "ResultsCOh24v07.RData")
rm(list=ls())
print("finished processing tile h24v07")
#q("no")
