##---create image stacks based on row-path for further analysis
##-- prequel to generating the sen-slopes
##-- modified to use gap filled images

## WARNING: how are gf images being created from 1999 to 2003? - -check

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

## <- as.data.frame(substr(in.list, start=21, stop=26)) ## modified for gf from start=18, stop=23
for (i in 1:length(unique.pathrow)){ ## changed from in.pathrow
## i <- 2
    sel.pr <- unique.pathrow[i] ## changed from in.pathrow
    im.list <- subset(in.list, subset=(in.pathrow==sel.pr))## modified for gf from start=18, stop=23
    im.list <- im.list[order(substrRight(im.list, 4))] ## order years in sequence
    ## Only select gap filled data
    im.list <- im.list[grep(pattern="max.gf", x=im.list)]
    
    ## WHY ARE WE GETTING GF IMAGES FOR YEARS 1999 TO 2003
    ## remove gf.pathrow 99 to 2002 and max.pathrow 2005 onwards
    ## im.list <- im.list[c(-1:-3, -14:-20)]
    im.onelist <- str_c(im.list,collapse=",")
    im.years <- substrRight(im.list, 4) ## modified for gf from start= 24, stop=27
    execGRASS("g.region",
              flags=c("p"),
              parameters=list(raster=im.onelist, res='6000')## FIX RESOLUTION
              ) ## set region to first image in stack. Reset resolution to desired level if required.
    for(j in 1:length(im.list)){
        ## for(j in 1:4){
        rst <- paste("rst",j, sep="")
        assign(rst, raster(readRAST6(im.list[j])))
    }
    rsts <- paste("rst", 1:length(im.list), sep="")
    ## rsts <- paste("rst", 1:4, sep="")
    yrs <- substrRight(im.list, 4)
    for(l1 in 1: length(rsts)){
        ## l1<-1
        x <- get(rsts[l1])
        rst.rows <- nrow(x)
        no.slices <- 2 ## will divide the rasters into slices. Change if needed
        slice.rows <- rst.rows/no.slices
        slice.rowsize <- round(c(slice.rows*1:no.slices))
        slice.name <- paste("slice", 1:no.slices, sep="")
        registerDoParallel(cores=12)
        fe.out <- foreach(l2=1:length(slice.name), .packages='raster') %dopar% {
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
        }
        rsts.list <- paste(rsts[l1],".list", sep="")
        assign(rsts.list, fe.out)
    }
    ## try and merge this loop into the earlier one so that the zyp.trend is run on the slices and only the final result is merged

    ### blank<-raster(get(rsts[1]))
blank <- get(rsts[1])
    ## rm(list=rsts)
    ## rm(x, fe.out)
    r.ls <- paste(rsts, "list", sep=".")
   ## for(l3 in 1:length(slice.name)){
    sen <- foreach(l3=1:length(slice.name), .combine='rbind', .packages=c('zyp', 'raster')) %dopar% { 

        for(l4 in 1:length(r.ls)){
        ## for(l4 in 1:3){
            ##rl <- foreach(l4=1:length(r.ls)) %do% {
            ##    b <- foreach(l4=1:length(r.ls), .combine=brick, .packages=c('raster')) %do% {
            ## rl <- get(r.ls[l4])[[l3]]
            tmp.br <- get(r.ls[l4])[[l3]]
            lyr <- paste("lyr.", l4, sep="")
            assign(lyr, tmp.br)
        }
        lyrs <- paste("lyr.",1:l4, sep="")
        b <- brick(lapply(lyrs, get))
### rm(rl)
        n <- cellsFromExtent(b,extent(b))
        nxy <- xyFromCell(b, n)
        val <- extract(b, nxy, df=TRUE)
        ## val <- as.data.frame(extract(b,c(1:ncell(b))))
        ## val <- as.data.frame(extract(b, extent(b)))
        ## val3 <- as.data.frame(extract(b,n))
        ## replace NaN values with NA
        ## val[is.na(val)] <- NA
        ## rm(b)
        ## if(nrow(val[complete.cases(val),]>0)){
        zyp.trend.dataframe(val,0,"zhang",conf.intervals=TRUE, preserve.range.for.sig.test=TRUE)
        ##    zyp.trend.dataframe(val,0,"yuepilon",conf.intervals=TRUE, preserve.range.for.sig.test=TRUE)
        }
            
}
    res.path <-  "/media/rsb/rsb/rsb/OngoingProjects/CEPF_monitoring/rdata/results/"
    sen.file <- paste(res.path,"sen_", sel.pr,".csv", sep="")
    slope.img <- paste(res.path,"sen_slope", sel.pr,".tif", sep="")
    slopet.img <- paste(res.path,"sen_slopet", sel.pr,".tif", sep="")
    tau.img <- paste(res.path,"sen_tau", sel.pr,".tif", sep="")
    sig.img <- paste(res.path,"sen_sig", sel.pr,".tif", sep="")
    sensummary.file <- paste(res.path,"sen_", sel.pr,".txt", sep="")
    slopeHist.img <- paste(res.path,"sen_slope_hist", sel.pr,".png", sep="")
    write.csv(file=sen.file, x=sen)   
    write.table(summary(sen), file=sensummary.file)
    writeRaster(setValues(blank, sen$trend), slope.img, format="GTiff", overwrite=TRUE)
    writeRaster( setValues(blank, sen$trendp), slopet.img, format="GTiff", overwrite=TRUE)
    writeRaster(setValues(blank, sen$sig), sig.img, format="GTiff", overwrite=TRUE)
    writeRaster(setValues(blank, sen$tau), tau.img, format="GTiff", overwrite=TRUE)
    png(slopeHist.img)
    hist(sen$trend)
    dev.off()
    
    ## clean up
    rm(sen, blank)
    rm(list=r.ls)
}
##-------cleare memory. USE WITH CAUTION---------##
##--------Loop not yet finished as sen extraction not working as desired
## rm(list=ls())



    ## ------- lines below if you wan to skip the slicing and dicing -------### 
    ## blank<-raster(get(rsts[1])) ## to be used to plot sen-slope raster
    ## brk.lst <- foreach(brkl=1:length(rsts), .packages='raster') %dopar% { ##.combine=brick doesn't work. Why?
    ##         get(rsts[brkl])
    ##     }
    ## brk <- brick(brk.lst)
    ## nbrk <- cellsFromExtent(brk,extent(brk))
    ## brk.val <- as.data.frame(extract(brk,c(1:ncell(brk)))) 
    ## sen.brk <- zyp.trend.dataframe(brk.val,1,"zhang",conf.intervals=TRUE)
    ## slope1 <- setValues(blank, sen.brk$trend)
    ## slopet1<- setValues(blank, sen.brk$trendp)
    ## sig1<- setValues(blank, sen.brk$sig)
    ## tau1<- setValues(blank, sen.brk$tau)
    ## image(slopet1)
    ## summary(sen)
    ## hist(slope)
    ## head(brk)  
