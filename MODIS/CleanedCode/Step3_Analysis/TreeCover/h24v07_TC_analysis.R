library(raster)
library(rgdal)
library(zoo)
library(zyp)
#### Set working directory ####
setwd("/media/MOD44_B/h24v07/")
#### Read tree cover Data frame ####
h24v07trcov.m.df<- read.csv("h24v07trcov.m.df.csv",header=T)

###Run sen slope###
sen_trcov.h24v07.raw<-zyp.trend.dataframe(h24v07trcov.m.df, metadata.cols=1, 
                                          method=c("yuepilon"),
                                          conf.intervals=TRUE, preserve.range.for.sig.test=TRUE)
blank<-raster(h24v07trcov.m, layer=1)
blank<-reclassify(blank, c(-Inf,Inf,NA))

h24v07trcovtrendp <- setValues(blank, sen_trcov.h24v07.raw$trendp)
h24v07trcovsig<-setValues(blank,sen_trcov.h24v07.raw$sig)
h24v07trcovsig <- reclassify(h24v07trcovsig, c(-Inf,0.1,1, 0.1,Inf,NA))
h24v07trcovtrendp.sig<-(h24v07trcovtrendp*h24v07trcovsig)

### Writing results to raster ###
setwd("/media/MOD44_B/results")
writeRaster(h24v07trcovtrendp.sig,filename= "h24v07trcovtrendp_sig.grd", datatype='FLT4S', overwrite=TRUE)
writeRaster(h24v07trcovtrendp,filename= "h24v07trcovtrendp.grd", datatype='FLT4S', overwrite=TRUE)

### Save data ###
setwd("/media/MOD44_B/h24v07/")
save.image("ResultsTCh24v07.RData")
rm(list=ls())
#q("no")
