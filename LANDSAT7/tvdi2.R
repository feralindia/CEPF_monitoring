## This is part two of the TVDI extraction
## Reads in output of first script to solve the TVDI equation.

## decide if you want to calculate TVDI or the ZWD parameter w or both
run.tvdi <- TRUE
run.w <- TRUE

source("LoadLibs.R")
source("LoadFuncts.R")
## load libs

## file locations
res <- "/home/pambu/rsb/OngoingProjects/CEPF_monitoring/rdata/results/tvdi/"
slp.int.csv <- "/home/pambu/rsb/OngoingProjects/CEPF_monitoring/rdata/results/tvdi/slp.int.csv"
execGRASS("g.mapset", mapset='tvdi')

## Decide whether to use gapfilling or not. It might create artifacts.
lst.list <- execGRASS("g.list", type='raster', pattern='gf.lst.*', exclude='*cel*', mapset='pet', intern=TRUE)
ndvi.list <- execGRASS("g.list", type='raster', pattern='gf.toar.ndvi.*', mapset='ndvi', intern=TRUE)
## lst.list <- execGRASS("g.list", type='raster', pattern='lst.*', exclude='*cel*', mapset='pet', intern=TRUE)
## ndvi.list <- execGRASS("g.list", type='raster', pattern='toar.ndvi.*', mapset='ndvi', intern=TRUE)
lst.id <- substrRight(lst.list, 21) 
ndvi.id <- substrRight(ndvi.list, 21)
lst.list <- lst.list[lst.id %in% ndvi.id]
ndvi.list <- ndvi.list[ndvi.id %in% lst.id]


ab.df <- read.csv(slp.int.csv, header=T, sep=",")
img.yr <- ab.df$year
## for (i in 1:nrow(ab.df)){ ## starting from 2005
for(i in 15:length(img.yr)){
    ## identify images
    ndvi.yr <- ndvi.list[grep(pattern=img.yr[i], ndvi.list)]
    lst.yr <- lst.list[grep(pattern=img.yr[i], lst.list)]
    
    lst.yr.id <- substrRight(lst.yr, 21)
    ndvi.yr.id <- substrRight(ndvi.yr, 21)
    ## Ensure ndvi and lst files match
    lst.yr <- lst.yr[lst.yr.id %in% ndvi.yr.id]
    ndvi.yr <- ndvi.yr[ndvi.yr.id %in% lst.id]
    a <- ab.df$a[i]
    b <- ab.df$b[i]
    ## Tmin <- ab.df$Tmin[i] ## Changed to accommodate 3 min values
    Tabsmin <- ab.df$Tabsmin[i]
    ## Tmeanmin <- ab.df$Tmeanmin[i]
    ## Tmedianmin <- ab.df$Tmedianmin[i]
    for(j in 1: length(lst.yr) ){
        lst.lyr <-  paste(lst.yr[j], "@pet", sep="")
        ndvi.lyr <-  paste(ndvi.yr[j], "@ndvi", sep="")
        ## fix the names to include three outputs based on Tmin
        ##v tvdi.nm <-  gsub(x=paste(ndvi.yr[j], sep=""), pattern="ndvi", replacement="tvdi")
        tvdiTabsmin.nm <-  gsub(x=paste(ndvi.yr[j], sep=""), pattern="ndvi", replacement="tvdiTabsmin")
        wTabsmin.nm <-  gsub(x=paste(ndvi.yr[j], sep=""), pattern="ndvi", replacement="w")
        ## tvdiTmeanmin.nm <-  gsub(x=paste(ndvi.yr[j], sep=""), pattern="ndvi", replacement="tvdiTmeanmin")
        ##gsub(x=paste(ndvi.yr[j], sep=""), pattern="ndvi", replacement="tvdiTabsmin")
        ## tvdiTmedianmin.nm <-  gsub(x=paste(ndvi.yr[j], sep=""), pattern="ndvi", replacement="tvdiTmedianmin")
        tvdiTabsmin.tif <-  paste(res, tvdiTabsmin.nm, ".tif", sep="")
        ## tvdiTmeanmin.lyr <-  paste(res, tvdiTmeanmin.nm, ".tif", sep="")
        ## tvdiTmedianmin.lyr <-  paste(res, tvdiTmedianmin.nm, ".tif", sep="")
        

        tvdiTabsmin.grass <-  paste(tvdiTabsmin.nm, "@tvdi", sep="")
        wTabsmin.grass <-  paste(wTabsmin.nm, "@tvdi", sep="")
        ## tvdiTmeanmin.grass <-  paste(tvdiTmeanmin.nm, "@tvdi", sep="")
        ## tvdiTmedianmin.grass <-  paste(tvdiTmedianmin.nm, "@tvdi", sep="")

        ## tvdi.grass <- paste(tvdi.nm, "@tvdi", sep="")
        reg.lst <- execGRASS("g.region", flags='p', raster=lst.lyr, res='30', intern=T)
        reg.ndvi <- execGRASS("g.region", flags='p', raster=ndvi.lyr, res='30', intern=T)
        ## ensure the no of cells is reasonable
        ncell.ndvi <- as.numeric(gsub("[^0-9]", "", reg.ndvi[13]))
        ncell.lst <- as.numeric(gsub("[^0-9]", "", reg.lst[13]))
        if(ncell.ndvi<75000000 & ncell.lst <75000000 & ncell.ndvi==ncell.lst){
            execGRASS("g.region", raster=ndvi.lyr, res='30')
            ndvi.in <- raster(readRAST6(ndvi.lyr))
            ndvi.ext <- extent(ndvi.in)
            ## --- generate tvdi
            if(run.tvdi==TRUE){
                execGRASS("g.region", raster=lst.lyr, res='30')
                lst.in <- raster(readRAST6(lst.lyr))
                lst.ext<-extent(lst.in)
                if(lst.ext==ndvi.ext){
                    lst.ndvi.br <- brick(c(lst.in, ndvi.in))
                    ## ndvi.lst.df<-as.data.frame(brick.ndvi.lst)
                    tmp <-extract(lst.ndvi.br, lst.ext, df=T)
                    colnames(tmp)<-c("lst","ndvi")
                    tmp$a <- a
                    tmp$b <- b
                    ## Generate three tvdi maps called absmin, meanmin and medianmin
                    ## based on the three minimum temperature calculations.
                    ## Given that absmin is 3 to 4 deg lower than the other two
                    ## we might get different results.
                    
                    tmp$Tabsmin <- Tabsmin
                    tmp$tvdiTabsmin <- (tmp$lst-tmp$Tabsmin)/(tmp$a+tmp$b*tmp$ndvi-tmp$Tabsmin)
                    
                    ## tmp$Tmeanmin <- Tmeanmin
                    ## tmp$tvdiTmeanmin <- (tmp$lst-tmp$Tmeanmin)/(tmp$a+tmp$b*tmp$ndvi-tmp$Tmeanmin)
                    
                    ## tmp$Tmedianmin <- Tmedianmin
                    ## tmp$tvdiTmedianmin <- (tmp$lst-tmp$Tmedianmin)/(tmp$a+tmp$b*tmp$ndvi-tmp$Tmedianmin)
                    
                    blank <- ndvi.in
                    names(blank) <- "tvdi"
                    blank[ndvi.in] <- NA
                    
                    tvdiTabsmin.rst <- setValues(blank, tmp$tvdiTabsmin)
                    ## tvdiTmeanmin.rst <- setValues(blank, tmp$tvdiTmeanmin)
                    ## tvdiTmedianmin.rst <- setValues(blank, tmp$tvdiTmedianmin)
                    
                    ## fix the names
                    writeRaster(tvdiTabsmin.rst, tvdiTabsmin.tif, format="GTiff", overwrite=TRUE, options=c("COMPRESS=DEFLATE", "ZLEVEL=9"))
                    ## writeRaster(tvdiTmeanmin.rst, tvdiTmeanmin.lyr, format="GTiff", overwrite=TRUE, options=c("COMPRESS=DEFLATE", "ZLEVEL=9"))
                    ## writeRaster(tvdiTmedianmin.rst, tvdiTmedianmin.lyr, format="GTiff", overwrite=TRUE, options=c("COMPRESS=DEFLATE", "ZLEVEL=9"))
                    sgdf.rast <- as(tvdiTabsmin.rst, 'SpatialGridDataFrame')
                    writeRAST6(sgdf.rast, tvdiTabsmin.grass, useGDAL = TRUE, zcol=1, ignore.stderr=TRUE, overwrite=TRUE) ##, useGDAL = TRUE, zcol=1, ignore.stderr=TRUE)  ## NEEDS TESTING 33 EXTRA COMMA REMOVED AFTER GRASS FILENAME
                    print(paste(tvdiTabsmin.nm, " written", sep=""))
                    ## plot(tvdi.rst)
                }
            }
            if(run.w==TRUE){
                expr.w <- paste(wTabsmin.nm, "= if ((", ndvi.lyr, " > 0.1 && ", tvdiTabsmin.grass, " > 0.0 &&", tvdiTabsmin.grass, " < 1.0),(1.5*(1.0 - (", tvdiTabsmin.grass, " ))) +0.5 ,0)", sep=" ")
                
                execGRASS("r.mapcalc",
                          flags="overwrite",
                          expression=expr.w)
                print(paste(wTabsmin.nm, " written", sep=""))
            }
        }
    }
}

