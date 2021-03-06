library(dlm)
library(raster)
library(zyp)
library(zoo)
library(stringr)

#### Set working directory ####
setwd("/media/MOD13_Q1/h24v07")
source("/media/functions/dlm2covarintercept_15FEB2015.R")
#### Read datasets ####
load("ndvi_h24v07.RData")

#### Running DLM on NDVI ####
intslp.h24v07.annual<-dlmtwocovar(h24v07ndvi.JFMAMOND.median,rain.h24v07.JFMAMOND,degC.h24v07.JFMAMOND)
#### Running Sen's slopes on DLM outputs ####
ndvi.h24v07.annual.int<-intslp.h24v07.annual[,1:(length(intslp.h24v07.annual)/3)]
sen_dlm_int<-zyp.trend.dataframe(ndvi.h24v07.annual.int,0,"zhang",conf.intervals=TRUE, preserve.range.for.sig.test=TRUE)
#### Raw trend in NDVI ###
sen_raw<-zyp.trend.dataframe(h24v07ndvi.JFMAMOND.median,0,"zhang",conf.intervals=TRUE, preserve.range.for.sig.test=TRUE)
#### Exporting to rasters ####
h24v07annualtrendp<- setValues(blank, sen_dlm_int$trendp)
h24v07annualsig<-setValues(blank,sen_dlm_int$sig)
h24v07annualsig<- reclassify(h24v07annualsig, c(-Inf,0.1,1, 0.1,Inf,NA))
h24v07annualtrendp.sig<-((h24v07annualtrendp*h24v07annualsig))

h24v07annualrawtrendp<- setValues(blank, sen_raw$trendp)
h24v07annualrawsig<-setValues(blank,sen_raw$sig)
h24v07annualrawsig<- reclassify(h24v07annualrawsig, c(-Inf,0.1,1, 0.1,Inf,NA))
h24v07annualrawtrendp.sig<-((h24v07annualrawtrendp*h24v07annualrawsig))

### Writing results to raster ###
setwd("/media/MOD13_Q1/results")
writeRaster(h24v07annualtrendp.sig,"h24v07_annual_ndvi_trendsig.grd",
            datatype='FLT4S',overwrite=T)
writeRaster(h24v07annualtrendp,"h24v07_annaul_ndvi_trend.grd",
            datatype='FLT4S',overwrite=T)
writeRaster(h24v07annualrawtrendp.sig,"h24v07_annualraw_ndvi_trendsig.grd",
            datatype='FLT4S',overwrite=T)
writeRaster(h24v07annualrawtrendp, "h24v07_annualraw_ndvi_trend.grd",
            datatype='FLT4S',overwrite=T)
save.image("Resultsvegh24v07.RData")
rm(list=ls())
print("Finished processing tile h24v07")
#q("no")
