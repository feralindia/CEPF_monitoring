### This section calls scripts to analyse each tile ###
### Depending on the computer capability decide how many tile will be processed ###
### The analysis can be time consuming and will require a minimum of 24 gb RAM ###
### You can distribute the computing by copying the data and relevent script and run them individually on different computers ###
### You can also run multiple instances of R to process individual tiles if you have a high end desktop, ###
### to do so uncomment the last line in each of the source files ###
source("/media/MOD44_B/h24v06/h24v06_TC_analysis.R")
source("/media/MOD44_B/h24v07/h24v07_TC_analysis.R")
source("/media/MOD44_B/h25v07/h25v07_TC_analysis.R")
source("/media/MOD44_B/h25v08/h25v08_TC_analysis.R")


library(raster)
library(rgdal)

#### Set working directory ####
setwd("/media/MOD44_B/results")

#### lst all raster files ####
s1 <- list.files(pattern="grd$",)
for (i in s1){
  assign(paste(i), raster(i))}
### Before mosaicing the tiles check resolution ###
### MOD16A2 has a spatial resolution of 1000m ###
res(h24v06_bw_yearlytrendpDLM.grd)
### Check all tiles ###
### If resolution has changed due to reprojection ###
### set it to 250m, you cannot mosaic tiles of different resolution ###
h24v06_bw_yearlytrendpDLM.grd<- projectRaster(h24v06_bw_yearlytrendpDLM.grd, 
                                              crs="+proj=utm +no_defs +zone=43 +a=6378137 +rf=298.257223563 +towgs84=0.000,0.000,0.000 +to_meter=1",res=250)


##Mosaic all trend sig files##
treeCover_trend_sig<-mosaic(h24v06trcovtrendp_sig.grd,h24v07trcovtrendp_sig.grd,
                         h25v07trcovtrendp_sig.grd,h25v08trcovtrendp_sig.grd,
                       fun=mean,tolerance=1)

summary(treeCover_trend_sig)
plot(treeCover_trend_sig)

##Mosaic all raw_trend files##

treeCoverraw_trend<-mosaic(h24v06trcovtrendp.grd,h24v07trcovtrendp.grd,h25v07trcovtrendp.grd,
                           h25v08trcovtrendp.grd,fun=mean,tolerance=1)
##reclassify range to -100 to 100###
treeCover_trend_sig<-reclassify(treeCover_trend_sig, c(-1000,-100,-100,100,200,100)) ##complete deforestation can lead to -100
plot(treeCover_trend_sig)

treeCoverraw_trend<-reclassify(treeCoverraw_trend, c(-1000,-100,-100,100,200,100)) ##complete deforestation can lead to -100
plot(treeCoverraw_trend)

### Number of Pixel analysed ###
wg<-readOGR(dsn="/media/vector/", layer="WGhats_bounds_utm")

blank<-raster(treeCover_trend_sig)
blank<-reclassify(blank, c(-Inf,Inf,NA))
wgbound<-rasterize(wg,blank,fun="first")
plot(wgbound)
wgbound<-reclassify(wgbound, c(-Inf,Inf,1))
freq(wgbound)

### reapplying mask ###
treeCover_trend_sig<-mask(treeCover_trend_sig,wgbound)
plot(treeCover_trend_sig)

treeCoverraw_trend<-mask(treeCoverraw_trend,wgbound)
plot(treeCoverraw_trend)

### Write raster for making maps in QGIS ###
setwd("/media/CEPF_MONITORING/results")
writeRaster(treeCover_trend_sig, "TreeCover_trend_sig.tif", format="GTiff",datatype='FLT4S', overwrite=TRUE)
writeRaster(treeCoverraw_trend, "TreeCover_raw_trend.tif", format="GTiff",datatype='FLT4S', overwrite=TRUE)

### Tabular outputs ###
freq(treeCover_trend_sig>0)
freq(treeCoverraw_trend>0)
freq(ndvi_trend>0)
freq(ndvi_trend_sig>0)