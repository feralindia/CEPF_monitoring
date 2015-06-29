##---intro

## Script to do atmospheric correction of images using 6S algorithm
## Run only on i.landsat.toar radiance calculations <http://grasswiki.osgeo.org/wiki/Atmospheric_correction>
## Avoid if using DOS normalisation
## Uses multiple cores
## Runs as independent script, including file selection

##---libraries
library(spgrass6)
library(doParallel)
library(foreach)

##---intilise
execGRASS("g.mapset", mapset="l7corrected")
imgs <- execGRASS("g.list", type='raster', mapset='l7corrected', pattern='toar.ref.LE7*', intern=T)
imgs.rowpath <- unique(substr(imgs, start=13, stop=18))

##---start loop
registerDoParallel(cores=12)
for(i in 1:length(imgs.rowpath)){
    pat <- paste("*", imgs.rowpath[i], "*", sep="")
    tmp.rst <- execGRASS("g.list", type='raster', mapset='l7corrected', pattern=pat, intern=T)
    execGRASS("g.region", raster=tmp.rst[1], res=30)
    atcorred <- foreach(l2=1:length(tmp.rst), .combine='rbind', .packages=c('spgrass6')) %dopar% {

        
    atcorred <- foreach(l2=1:length(tmp.rst), .combine='rbind', .packages=c('spgrass6')) %dopar% {##---get 6S parameters from image metadata
        
        r.info lsat7_2002_40

        r.univar elevation
    
