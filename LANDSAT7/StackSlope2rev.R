##-- modified to use gap filled images
setwd("/home/rsb/Documents/RScripts/")

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
## for (i in 2:length(unique.pathrow)){ ## note that first raster is p143r53 in utm44
###------

i <- 2

####-------

# for(i in 1:5){
sel.pr <- unique.pathrow[i] ## changed from in.pathrow
im.list <- subset(in.list, subset=(in.pathrow==sel.pr))## modified for gf from start=18, stop=23
im.list <- im.list[order(substrRight(im.list, 4))] ## order years in sequence
## Only select gap filled data
im.list <- im.list[grep(pattern="max.gf", x=im.list)]
im.years <- substrRight(im.list, 4) ## modified for gf from start= 24, stop=27
execGRASS("g.region", raster=im.list[1], res='30') ## set region to first image in stack.

## MODIFIED TO REMOVE RASTERS WITH ONLY NULL VALUES Ma13th2015
## remove all objects with names with rst
rm (ls(pattern="rst"))
## create brick of only valid rasters
for(j in 1:length(im.list)){
    rst <- paste("rst",j, sep="")
    tmprst <- raster(readRAST6(im.list[j]))
    if(maxValue(tmprst)>0 & !is.na(maxValue(tmprst))){
        assign(rst, raster(tmprst))
        rm(tmprst)
    } else { 
        print(paste(im.list[j], "is null or has only 0 values.", sep=" "))
    }
}
## copy names of rasters to lyrs
lyrs <- ls(pattern="rst")[-1]
## create brick
x <- brick(lapply(lyrs, get))
rst.rows <- nrow(x)
no.slices <- 24 ## will divide the rasters into slices. Change if needed
slice.rows <- rst.rows/no.slices
slice.rowsize <- round(c(slice.rows*1:no.slices))
slice.name <- paste("slice", 1:no.slices, sep="")

registerDoParallel(cores=12)
sen <- foreach(l2=1:length(slice.name), .combine='rbind', .packages=c('raster', 'zyp')) %dopar% {
    sliced.rast <- slice.name[l2]
    r.prev <- slice.rowsize[l2-1]
    r.min <- if(l2==1){
        r.min=1} else {r.min=r.prev+1}
    r.max <- if(slice.rowsize[l2]+slice.rowsize[1]>rst.rows){
        r.max=rst.rows} else {r.max=slice.rowsize[l2]}
    r.min
    r.max
    c.min <- 1
    c.max <- ncol(rst1)
    ext.rst <- extent(rst1, r1=r.min, r2=r.max, c1=c.min, c2=c.max)
    sliced.rast <- crop(x, y=ext.rst)
    n <- cellsFromExtent(sliced.rast,extent(sliced.rast))
    nxy <- xyFromCell(sliced.rast, n)
    val <- extract(sliced.rast, nxy, df=TRUE)
    zyp.trend.dataframe(val,0,"zhang",conf.intervals=TRUE, preserve.range.for.sig.test=TRUE)
}

###------ RUN TILL HERE AT ONE GO AFTER INCREMENTING THE VALUE OF i

####-- THEN RUN THE REST LINE BY LINE


## res.path <-  "/media/rsb/rsb/rsb/OngoingProjects/CEPF_monitoring/rdata/results/"
res.path <-  "/home/rsb/Documents/SenResults/"
blank <- get(lyrs[1])
## setValues(blank, NA)
blank[ get(lyrs[1])] <- NA

sen.file <- paste(res.path,"sen_", sel.pr,".csv", sep="")
slope.img <- paste(res.path,"sen_slope", sel.pr,".tif", sep="")
slopet.img <- paste(res.path,"sen_slopet", sel.pr,".tif", sep="")
tau.img <- paste(res.path,"sen_tau", sel.pr,".tif", sep="")
sig.img <- paste(res.path,"sen_sig", sel.pr,".tif", sep="")
sensummary.file <- paste(res.path,"sen_", sel.pr,".txt", sep="")
slopeHist.img <- paste(res.path,"sen_slope_hist", sel.pr,".png", sep="")
write.csv(file=sen.file, x=sen)   
summ.sen <- summary(sen)
write.table(summ.sen, file=sensummary.file)
writeRaster(setValues(blank, sen$trend), slope.img, format="GTiff", overwrite=TRUE)
writeRaster( setValues(blank, sen$trendp), slopet.img, format="GTiff", overwrite=TRUE)
writeRaster(setValues(blank, sen$sig), sig.img, format="GTiff", overwrite=TRUE)
writeRaster(setValues(blank, sen$tau), tau.img, format="GTiff", overwrite=TRUE)
png(slopeHist.img)
try(hist(sen$trend))
dev.off()

## sen.clean <- sen[complete.cases(sen),]
## sen.clean <- subset(sen, select=c("trend", "trendp", "sig", "linear", "intercept", "tau"))
## sen.clean[is.na(sen.clean)] <- NaN
sen.clean <- sen
sen.clean$sig[sen.clean$sig > 0.1] <- NA
sen.clean$lbound[sen.clean$sig > 0.1] <- NA

##sen.clean$trend[sen.clean$sig > 0.1] <- NA
sen.clean$trend[sen.clean$trend < -1] <- NA
sen.clean$trend[sen.clean$trend < 0.15] <- NA

##sen.clean$trendp[sen.clean$sig > 0.1] <- NA
sen.clean$trendp[sen.clean$trendp < -1] <- NA
sen.clean$trendp[sen.clean$trendp > 1] <- NA

##sen.clean$ubound[sen.clean$sig > 0.1] <- NA

##sen.clean$tau[sen.clean$sig > 0.1] <- NA

##sen.clean$nruns[sen.clean$sig > 0.1] <- NA

##sen.clean$autocor[sen.clean$sig > 0.1] <- NA

##sen.clean$valid_frac[sen.clean$sig > 0.1] <- NA

##sen.clean$linear[sen.clean$sig > 0.1] <- NA

##sen.clean$intercept[sen.clean$sig > 0.1] <- NA

## sen.clean$sig[sen.clean$sig > 0.1] <- NA
## sen.clean$trend[sen.clean$trend < -0.15] <- NA

## sen.clean$trendp[sen.clean$trendp > 0.15] <- NA
## sen.clean$trendp[sen.clean$trendp < -0.15] <- NA

## Get limits from Srini
## sen.clean$trend[sen.clean$trend > -0.15] <- NA


sen.clean.file <- paste(res.path,"sen.clean_", sel.pr,".csv", sep="")
sen.cleansummary.file <- paste(res.path,"sen.clean_", sel.pr,".txt", sep="")
slope.img <- paste(res.path,"sen.clean_slope", sel.pr,".tif", sep="")
slopet.img <- paste(res.path,"sen.clean_slopet", sel.pr,".tif", sep="")
tau.img <- paste(res.path,"sen.clean_tau", sel.pr,".tif", sep="")
sig.img <- paste(res.path,"sen.clean_sig", sel.pr,".tif", sep="")
slopeHist.clean.img <- paste(res.path,"sen.clean_slope_hist", sel.pr,".png", sep="")

write.csv(file=sen.clean.file, x=sen.clean)   
summ.sen.clean <- summary(sen.clean)
write.table(summ.sen.clean, file=sen.cleansummary.file)
writeRaster(setValues(blank, sen.clean$trend), slope.img, format="GTiff", overwrite=TRUE)

writeRaster( setValues(blank, sen.clean$trendp), slopet.img, format="GTiff", overwrite=TRUE)

writeRaster(setValues(blank, sen.clean$sig), sig.img, format="GTiff", overwrite=TRUE)
writeRaster(setValues(blank, sen.clean$tau), tau.img, format="GTiff", overwrite=TRUE)
png(slopeHist.clean.img)
try(hist(sen.clean$trend))
dev.off()
try(hist(sen.clean$trend))

## clean up
##    rm(sen, blank)

