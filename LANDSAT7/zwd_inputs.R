##--- Import precipitation as a raster brick then move into GRASS for inerpolation
## Only run once.
## trmm.dirloc <- "/maps2/TRMM_yearly/"
## trmm.flnm <- paste(trmm.dirloc, "TRMM_yearly_3.gri", sep="")
## trmm.brk <- brick(trmm.flnm)
## yrs <- 2000:2013
## execGRASS("g.mapset", mapset='trmm')
## for(i in 1:nlayers(trmm.brk)){
##     P.yr.in <- as(subset(trmm.brk, subset=i, drop=TRUE), 'SpatialGridDataFrame')
##     P.yr.out <- paste("Pyr", yrs[i], ".trmm", sep="")
##     writeRAST6(P.yr.in, P.yr.out, useGDAL = TRUE, zcol=1,
##                ignore.stderr=TRUE, overwrite=TRUE)
## }
##-- get MODIS data
## execGRASS("g.mapset", mapset="modis")
## execGRASS("g.region", res='1000')
## modis.dirloc <- "/home/pambu/maps2/MOD16_ET"
## modis.fullnm <- list.files(modis.dirloc, recursive=TRUE, full.names=TRUE, pattern="[0-9]ET_1km.tif")
## modis.flnm <- substr(modis.fullnm, start=35, stop=50)
## for(i in 1:length(modis.fullnm)){
##     modis.in <- modis.fullnm[i]
##     modis.out <- modis.flnm[i]
##     execGRASS("r.in.gdal", input=modis.in, output=modis.out, flags=c("overwrite", "e", "o"))
## }

##--PET data

 ## execGRASS("g.mapset", mapset="modis")
 ## execGRASS("g.region", res='1000')
 ## modis.dirloc <- "/home/pambu/maps2/MOD16_ET"
 ## modis.fullnm <- list.files(modis.dirloc, recursive=TRUE, full.names=TRUE, pattern="PET_1km.tif")
 ## modis.flnm <- substr(modis.fullnm, start=35, stop=51)
 ## for(i in 1:length(modis.fullnm)){
 ##     modis.in <- modis.fullnm[i]
 ##     modis.out <- modis.flnm[i]
 ##     execGRASS("r.in.gdal", input=modis.in, output=modis.out, flags=c("overwrite", "e", "o"))
 ## }

##--get median of all w data---###
## run only once
## execGRASS("g.mapset", mapset='tvdi')
## for(i in 1:length(yrs.w)){
##     yr.in.w <- subset(list.w, subset=substr(list.w, start=20, stop=23)==yrs.w[i])
##     for(j in 1: length(rc.w)){
##         rc.w.in <- subset(yr.in.w, subset=substr(yr.in.w, start=14, stop=19)==rc.w[j])
##         out.w <- paste("gf.toar.median.w.",rc.w[j], yrs.w[i], sep="")
##         if(length(rc.w.in>0)){
##             execGRASS("g.region", raster=rc.w.in[1])
##             execGRASS("r.series", flags="overwrite", input=rc.w.in, output=out.w, method='median')
##             ## either continue with appropriate year
##             ## for modis and trmm or do it in seperate routines
##             print(c(paste("Getting median values for raster:", rc.w.in, sep=" "),
##                   paste("Raster", i, "of", length(yrs.w), ":", out.w, "created", sep=" ")))
##         }
##     }
## }



##-- get annual evapotranspiration, not needed
##-- using annual product instead
## execGRASS("g.mapset", mapset='modis')
## yrs.pet <- unique(substr(list.pet, start=0, stop=5))
## rc.pet <- unique(substr(list.pet, start=9, stop=14))
## for(i in 1:length(yrs.pet)){
##     yr.in.pet <- subset(list.pet, subset=substr(list.pet, start=0, stop=5)==yrs.pet[i])
##     for(j in 1: length(rc.pet)){
##         rc.pet.in <- subset(yr.in.pet, subset=substr(yr.in.pet, start=9, stop=14)==rc.pet[j])
##         out.pet <- paste(yrs.pet[i], rc.pet[j],"annPET", sep="")
##         if(length(rc.pet.in>0)){
##             execGRASS("g.region", raster=rc.pet.in[1])
##             execGRASS("r.series", flags="overwrite", input=rc.pet.in, output=out.pet, method='sum')
##             ##            r.series --overwrite --quiet input=A2000M01h24v06PET,A2000M02h24v06PET,
##             ## A2000M03h24v06PET,A2000M04h24v06PET output=A2000h24v06annPET method=sum
##              print(c(paste("Getting median values for raster:", rc.pet.in, sep=" "),
##                      paste("Raster", i, "of", length(yrs.pet), ":", out.pet, "created", sep=" ")))
##          }
##      }
##  }




##--- get the annual PET ---##

##--- get the annual precip ---##

##--- get the annual w ---##


## interpolate the trmm -need to readup here
## caution with region - should extend well beyond the trmm
## r.resamp.interp --overwrite input=Pyr2000.trmm@trmm output=Pyr2000.trmm.bil
##--select relevant rasters from MODIS and TRMM--##
## for loop
## create region corresponding to tile

##-- import annual MODIS and interpolate using bilinear
##-- ensure there is a MASK

## list.modis <- execGRASS("g.list", type='raster', pattern=pat.modis, exclude="A2014365", mapset='modis',intern=TRUE)

