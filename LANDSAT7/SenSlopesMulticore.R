##-- modified to use gap filled images
setwd("/home/rsb/Documents/RScripts/")

library(snow)

source("ControlScript.R", echo=TRUE) 

execGRASS("g.mapset", mapset='ndvi')
in.list.mpset <- execGRASS("g.list",
                           flags=c("m","r", "quiet"),
                           parameters=list(type='raster', mapset='ndvi', pattern='max'), intern=TRUE)
## Pattern should allow both gf and non gf images

in.list <- execGRASS("g.list",
                     flags=c("r", "quiet"),
                     parameters=list(type='raster', mapset='ndvi', pattern='max'), intern=TRUE)
in.pathrow <- substrRight(in.list, 10)
in.pathrow <- substrLeft(in.pathrow, 4)
unique.pathrow <- in.pathrow[!duplicated(in.pathrow)]
in.path <- substrLeft(unique.pathrow, 3) ## modified for gf from start=18, stop=20
unique.path <- in.path[!duplicated(in.path)]
in.row <- substrRight(unique.pathrow, 3) ## modified for gf from start=21, stop=23
unique.row <- in.row[!duplicated(in.row)]

## AVOID USING A LOOP - THE MACHINE RUNS OUT OF MEMORY.
## NEED TO FLUSH THE MEMORY BEFORE EACH RUN
## for (i in 1:length(unique.pathrow)){ ## note that first raster is p143r53 in utm44
###------

## for(i in c(6:10)){
## tile 6 not working, needs to be re-run May 21st 2015
## Note tile 14 and 16 is outside mask
i <- 18
sel.pr <- unique.pathrow[i] ## changed from in.pathrow
im.list <- subset(in.list, subset=(in.pathrow==sel.pr))## modified for gf from start=18, stop=23
im.list <- im.list[order(substrRight(im.list, 4))] ## order years in sequence
## Only select gap filled data
im.list <- im.list[grep(pattern="max.gf", x=im.list)]
im.years <- substrRight(im.list, 4) ## modified for gf from start= 24, stop=27
execGRASS("g.region", raster=im.list[1], res='30') ## set region to first image in stack.

## ## MODIFIED TO REMOVE RASTERS WITH ONLY NULL VALUES May13th2015
## ## remove all objects with names with rst
## rm.rst<- ls(pattern="rst")
## rm(list=rm.rst)
## ## create brick of only valid rasters
## for(j in 1:length(im.list)){
##     rst <- paste("rst",j, sep="")
##     tmprst <- raster(readRAST6(im.list[j]))
##     if(maxValue(tmprst)>0 & !is.na(maxValue(tmprst))){
##         assign(rst, tmprst)
##         rm(tmprst)
##         lyrs[j] <- rst
##     } else { 
##         print(paste(im.list[j], "is null or has only 0 values.", sep=" "))
##     }
## }

##---- insert null rasters for missing years

im.year.num <- sort(as.numeric(im.years))
all.yrs <- 1999:2013
seq.yrs <- 1:15
rst.exists <- all.yrs%in%im.year.num
miss.years <-  all.yrs[!all.yrs%in%im.year.num]
ord.miss.yrs <- seq.yrs[!all.yrs%in%im.year.num]
blank <- raster(readRAST6(im.list[1]))
## blank[blank] <- NA
blank <- setValues(blank, NA)
##plot(blank)
ext.rst <- extent(blank)
##--insert fillers into image list
full.im.list <- im.list
for(ord in 1:length(ord.miss.yrs)){
    full.im.list <- append(full.im.list, values=paste("year_", miss.years[ord],"_missing", sep=""), after=ord.miss.yrs[ord]-1)
}

for(j in 1:15){ ## there should be 15 rasters
    rst <- paste("rst",j, sep="")
    if(rst.exists[j]==TRUE){
        tmprst <- raster(readRAST6(full.im.list[j]))
    }else{tmprst <- blank}
   ##  plot(tmprst)      
    assign(rst, tmprst)
    lyrs[j] <- rst
    rm(tmprst)
}
## check to see if extents match
## for(e in 2:length(lyrs)){
##    if(extent(get(lyrs[e-1]))==extent(get(lyrs[e]))){
##         print(paste("Extents of rasters", e-1, "and", e, "match", sep=" "))
##     }else{
##          print(paste("Extents of rasters", e-1, "and", e, "DO NOT MATCH", sep=" "))
##      }
## }


## create brick
modisbrick <- brick(lapply(lyrs, get))
## ext.brk <- extent(brk)
plot(modisbrick)
rm(list=lyrs)


##--begin Srini's multicore code
## A wrapper function to derive sen's slope (layer 1) and significant values (layer 2)
r.sen<-function(x) {
        fit<-zyp.trend.vector(x, method="zhang",conf.intervals=T)
                                        #trendp<-fit[3]
                                        #pval<-fit[6]
        return(cbind(fit[3], fit[6]))
    }

 ff <- function(x){
        calc(x, r.sen)
    }

beginCluster(12)
cl <-getCluster()
y2 <- clusterR(modisbrick, fun = ff, export = "r.sen")
endCluster()

res.path <-  "/home/rsb/Documents/SenResults/"

##--end multicore

plot(y2)
trend <- raster(y2, layer=1)
trend.img <- paste(res.path,"sen_trend", sel.pr,".tif", sep="")
pval <- raster(y2, layer=2)
pval.img <- paste(res.path,"sen_pval", sel.pr,".tif", sep="")
## trend.out <- paste(resdir,"trend", rc.Blue[i], ".tif", sep="")
## pval.out <- paste(resdir,"pval", rc.Blue[i], ".tif", sep="")
writeRaster(trend, filename=trend.img, format="GTiff", overwrite=TRUE)
writeRaster(pval, filename=pval.img, format="GTiff", overwrite=TRUE)




## ## val <- extract(brk, ext.brk, df=TRUE) ## , sp=TRUE, method='simple'
## ## sen <- zyp.trend.dataframe(val,0,"zhang",conf.intervals=TRUE, preserve.range.for.sig.test=TRUE)

## ## ext.brk <- extent(brk)
## ## mincol.brk <- ext.brk[1] ##x is cols y is rows
## ## maxcol.brk <- ext.brk[2]
## ## minrow.brk <- ext.brk[3] ## x is cols y is rows
## ## maxrow.brk <- ext.brk[4]
## ## brk.rows <- maxrow.brk-minrow.brk
## ## no.slices <- 15 ## will divide the rasters into slices. Change if needed
## ## slice.rows <- round(brk.rows/no.slices)
## ## slice.rowsize <- round(c(slice.rows*1:no.slices))
## ## slice.name <- paste("slice", 1:no.slices, sep="")
## ## ## n <- 1
## ## ## n <- 2
## ## ## initialise values
## ## row.max <- maxrow.brk
## ## row.min <- row.max-slice.rows
## ## col.min <- mincol.brk
## ## col.max <- maxcol.brk

## ## registerDoParallel(cores=12)
## ## sen <- foreach(l2=1:no.slices, .combine='rbind', .packages=c('raster', 'zyp')) %dopar% {
## ##   ##  sl <- paste("slice", l2, sep="")
## ##   ##  ext.sl <-  paste("ext.sl", l2, sep="")
## ##   ##  vl <- paste("val", l2, sep="")
## ##   ##  sn <- paste("sen", l2, sep="")
## ##     if(row.min <= minrow.brk){
## ##         row.min <- minrow.brk
## ##     }
## ##     ext.slice <- extent(c(r1=col.min, r2=col.max, c1=row.min,c2= row.max))
## ##     slice <- crop(x=brk, y=ext.slice, snap="out") ##, snap="out"
## ##     val <- extract(slice, ext.slice, df=TRUE) ## , sp=TRUE, method='simple'
## ##     ## val <- getValues(slice)
## ##     row.max <- row.min
## ##     row.min <- row.max-slice.rows
## ##     sen <- zyp.trend.dataframe(val,0,"zhang",conf.intervals=TRUE, preserve.range.for.sig.test=TRUE)
## ##     ## assign(sl, slice)
## ##     ## assign(ext.sl, ext.slice)
## ##     ## assign(vl, val)
## ##     ## assign(sn, sen)
## ##     rm(list=c("slice","ext.slice","val"))
## ##     sen
## ## }
## ##--- remove extra rows at the bottom of the dataframe---##
## ncells <- ncell(brk)
## nrows <- nrow(sen)
## if(ncells!=nrows){
##     ex.strow <- ncells+1
##     sen <- sen[(c(-ex.strow:-nrows)),]}
## ## new.sen <- sen[c(-12169:-nrow(sen)),]
## ##sen0 <- sen
## ## sen <- rbind(sen,sen0)
## names(sen)
## ## names(sen) <- c("lbound", "trend", "trendp","ubound", "tau", "sig", "nruns", "autocor","valid_frac", "linear", "intercept")

## ###------ RUN TILL HERE AT ONE GO AFTER INCREMENTING THE VALUE OF i

## ####-- THEN RUN THE REST LINE BY LINE


## ## res.path <-  "/media/rsb/rsb/rsb/OngoingProjects/CEPF_monitoring/rdata/results/"
## res.path <-  "/home/rsb/Documents/SenResults/"
## slope.img <- paste(res.path,"sen_slope", sel.pr,".tif", sep="")
## ##-- moved creation of blank raster up---May22nd2015
## ## blank <- subset(x, subset=1, drop=FALSE)
## ## setValues(blank, 10)
## ## blank[blank] <- 10
## ## plot(blank)
## ## image(blank)
## ## extent(blank)

## sen.file <- paste(res.path,"sen_", sel.pr,".csv", sep="")
## slope.img <- paste(res.path,"sen_slope", sel.pr,".tif", sep="")
## slopet.img <- paste(res.path,"sen_slopet", sel.pr,".tif", sep="")
## tau.img <- paste(res.path,"sen_tau", sel.pr,".tif", sep="")
## sig.img <- paste(res.path,"sen_sig", sel.pr,".tif", sep="")
## sensummary.file <- paste(res.path,"sen_", sel.pr,".txt", sep="")
## slopeHist.img <- paste(res.path,"sen_slope_hist", sel.pr,".png", sep="")
## write.csv(file=sen.file, x=sen)   
## summ.sen <- summary(sen)
## write.table(summ.sen, file=sensummary.file)

## blank <- (subset(brk, subset=1))
## write.r <- setValues(blank, sen$trend)
## #plot(write.r)


## writeRaster(write.r, slope.img, format="GTiff", overwrite=TRUE)
## writeRaster( setValues(blank, sen$trendp), slopet.img, format="GTiff", overwrite=TRUE)
## writeRaster(setValues(blank, sen$sig), sig.img, format="GTiff", overwrite=TRUE)
## writeRaster(setValues(blank, sen$tau), tau.img, format="GTiff", overwrite=TRUE)
## png(slopeHist.img)
## try(hist(sen$trend))
## dev.off()

## ## sen.clean <- sen[complete.cases(sen),]
## ## sen.clean <- subset(sen, select=c("trend", "trendp", "sig", "linear", "intercept", "tau"))
## ## sen.clean[is.na(sen.clean)] <- NaN
## sen.clean <- sen
## sen.clean$sig[sen.clean$sig > 0.1] <- NA
## sen.clean$lbound[sen.clean$sig > 0.1] <- NA

## ##sen.clean$trend[sen.clean$sig > 0.1] <- NA
## sen.clean$trend[sen.clean$trend < -1] <- NA
## sen.clean$trend[sen.clean$trend < 0.15] <- NA

## ##sen.clean$trendp[sen.clean$sig > 0.1] <- NA
## sen.clean$trendp[sen.clean$trendp < -1] <- NA
## sen.clean$trendp[sen.clean$trendp > 1] <- NA

## ##sen.clean$ubound[sen.clean$sig > 0.1] <- NA

## ##sen.clean$tau[sen.clean$sig > 0.1] <- NA

## ##sen.clean$nruns[sen.clean$sig > 0.1] <- NA

## ##sen.clean$autocor[sen.clean$sig > 0.1] <- NA

## ##sen.clean$valid_frac[sen.clean$sig > 0.1] <- NA

## ##sen.clean$linear[sen.clean$sig > 0.1] <- NA

## ##sen.clean$intercept[sen.clean$sig > 0.1] <- NA

## ## sen.clean$sig[sen.clean$sig > 0.1] <- NA
## ## sen.clean$trend[sen.clean$trend < -0.15] <- NA

## ## sen.clean$trendp[sen.clean$trendp > 0.15] <- NA
## ## sen.clean$trendp[sen.clean$trendp < -0.15] <- NA

## ## Get limits from Srini
## ## sen.clean$trend[sen.clean$trend > -0.15] <- NA


## sen.clean.file <- paste(res.path,"sen.clean_", sel.pr,".csv", sep="")
## sen.cleansummary.file <- paste(res.path,"sen.clean_", sel.pr,".txt", sep="")
## slope.img <- paste(res.path,"sen.clean_slope", sel.pr,".tif", sep="")
## slopet.img <- paste(res.path,"sen.clean_slopet", sel.pr,".tif", sep="")
## tau.img <- paste(res.path,"sen.clean_tau", sel.pr,".tif", sep="")
## sig.img <- paste(res.path,"sen.clean_sig", sel.pr,".tif", sep="")
## slopeHist.clean.img <- paste(res.path,"sen.clean_slope_hist", sel.pr,".png", sep="")

## write.csv(file=sen.clean.file, x=sen.clean)   
## summ.sen.clean <- summary(sen.clean)
## write.table(summ.sen.clean, file=sen.cleansummary.file)
## writeRaster(setValues(blank, sen.clean$trend), slope.img, format="GTiff", overwrite=TRUE)

## writeRaster( setValues(blank, sen.clean$trendp), slopet.img, format="GTiff", overwrite=TRUE)

## writeRaster(setValues(blank, sen.clean$sig), sig.img, format="GTiff", overwrite=TRUE)
## writeRaster(setValues(blank, sen.clean$tau), tau.img, format="GTiff", overwrite=TRUE)
## png(slopeHist.clean.img)
## try(hist(sen.clean$trend))
## dev.off()
## try(hist(sen.clean$trend))

## ## clean up
##  to.rm <- row.names(lsos(n=4))
##  rm(list=to.rm)

## ##}
