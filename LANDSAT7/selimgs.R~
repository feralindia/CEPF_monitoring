##--------------- select images based on dates, organise the files for subsequent processing

wd <- "./"
## wd <- "/home/pambu/rsb/OngoingProjects/CEPF_monitoring/rdata/LANDSAT7/" # changed to pambu
## setwd(wd)
if (!exists("img.df")){
    ls.file <- paste(wd, "folderlist/LSlist_Auto.csv", sep="")
    LS.list <- read.csv(file=ls.file, strip.white=TRUE, sep=",")
} else { LS.list <- img.df
     }
##error.file <- paste(wd, "folderlist/errors.csv", sep="") # removed missing files/folders

LS.list.dup <- LS.list[duplicated(LS.list), ] # identify duplicates,
## from <http://www.dummies.com/how-to/content/how-to-remove-duplicate-data-in-r.html>
LS.list <- LS.list[!duplicated(LS.list), ] # remove duplicates
startdate <- "1970-01-01" # specify default origin date as startdate
## ----- working with ETM only
ETM.list <- subset(LS.list, grepl("ETM", LS.list$Sensor))
ETM.list$Date<-as.Date(as.numeric(ETM.list$Date), origin=startdate) ##as.Date(ETM.list$Date, origin=startdate)
ETM.list$Month <- as.numeric(format.Date(ETM.list$Date, "%m"))
ETM.list <- unique(ETM.list) ## remove duplicates which have crept in
ETM.list <- na.omit(ETM.list[with(ETM.list, order(Date,ID, Path, Row)), ]) # sort remove NAs
##LS.years <- c(1999:2013)
LS.years <- 1999

all.summer <- subset(ETM.list, Month >= 3 & Month <= 5) # MAM based on IMD
all.winter <- subset(ETM.list, Month >= 10 & Month <= 12) # OND based on IMD

all.slc.on <- subset(ETM.list, !grepl("SLC-off", ETM.list$Sensor))
all.slc.off <- subset(ETM.list, grepl("SLC-off", ETM.list$Sensor))

slc.on.summer <- subset(ETM.list, Month >= 3 & Month <= 5 &  !grepl("SLC-off", ETM.list$Sensor))
slc.off.summer <- subset(ETM.list, Month >= 3 & Month <=5  &  grepl("SLC-off", ETM.list$Sensor))

slc.on.winter <- subset(ETM.list, Month >= 10 & Month <= 12 &  !grepl("SLC-off", ETM.list$Sensor))
slc.off.winter <- subset(ETM.list, Month >= 10 & Month <= 12 &  grepl("SLC-off", ETM.list$Sensor))

file.LSlist <- "./folderlist/LSlist.txt"
write.table(ETM.list, file=file.LSlist, row.names=FALSE, quote=FALSE)

## Get list of processed files from GRASS so processing isn't repeated
## pat <- "*toar.dos4*" ## 'toar.ndvi*'
## mset <- "l7corrected" ##'ndvi'
pat <- "gf.toar.ndvi*"   ##TO BE REVERTED
mset <- "ndvi" ##'ndvi'
fl.exists <- execGRASS("g.list",
                       parameters=list(type='raster', pattern=pat, mapset=mset),
                       intern=TRUE)
fl.exists <- fun.int2df(fl.exists)
fl.exists <- as.character(fl.exists$x1)
fl.exists <- substr(fl.exists, start=14, stop=34)##stop=nchar(fl.exists))
fl.exists <- as.data.frame(fl.exists)
head(fl.exists)
## fl.exists <- NULL

## Get list for max.ndvi and avg.ndvi images - use function raster.exists
## NOTE NDVI.EXISTS FUNCTION NEEDS TO BE CHANGED TRIMMING DATA
max.exists <- ndvi.exists("max*", "ndvi")
avg.exists <- ndvi.exists("avg*", "ndvi")
ems.exists <- pet.exists("ems*", "pet", 5, 26)
## lst.exists <- pet.exists("lst*", "pet", 5, 26)
## Modifying for gf.lst
lst.exists <- pet.exists("gf.lst*", "pet", 8, 29)
avg.lst.exists <- pet.exists("avg*", "pet", 8, 29) ## fix this
tas.exists <- pet.exists("toar.dos4*_B6_VCID_1*", "l7corrected", 11, 31)

## Get list of temperature at sensor (tas) images ## may be redundant
## tas.exists <- execGRASS("g.list",
##                       parameters=list(type='raster', pattern='toar.dos4*_B6_VCID_1*',
##                           mapset='l7corrected'), intern=TRUE)
## tas.exists <- substr(tas.exists, start=11, stop=31)
##  lst.exists <- substrRight(lst.exists, 21) ## may not be needed if function above works


## get year wise groups of images
##--- subset by years and write to text
## yr <- 1 ## to skip the loop below
for (yr in 1:length(LS.years)){
    ##      for(yr in 1:14){
    ## yr <- 1
    yrno <- LS.years[yr]

    file.all.summer <- paste("./folderlist/all.summer",LS.years[yr], "ETM.txt", sep="")
    file.all.winter <- paste("./folderlist/all.winter",LS.years[yr], "ETM.txt", sep="")

    file.all.slc.on <- paste("./folderlist/all.slc.on",LS.years[yr], "ETM.txt", sep="")
    file.all.slc.off <- paste("./folderlist/all.slc.off",LS.years[yr], "ETM.txt", sep="")
    
    file.slc.on.summer <- paste("./folderlist/slc.on.summer",LS.years[yr], "ETM.txt", sep="")
    file.slc.off.summer <- paste("./folderlist/slc.off.summer",LS.years[yr], "ETM.txt", sep="")
    
    file.slc.on.winter <- paste("./folderlist/slc.on.winter",LS.years[yr], "ETM.txt", sep="")
    file.slc.off.winter <- paste("./folderlist/slc.off.winter",LS.years[yr], "ETM.txt", sep="")
    
    yr.all.winter <- na.omit(subset(all.winter, format.Date(Date, "%Y")==yrno,
                                    select=c(Path, Row, ID, Date)))

    
    if(run.lscorr==TRUE){
        
        ## yr.all.summer <- na.omit(subset(all.summer, format.Date(Date, "%Y")==yrno, select=c(Path, Row, ID, Date)))
        ## img.list <- yr.all.summer
        ## if(nrow(img.list)>0) {source("lscorr.R", echo=TRUE)} # uncomment to run the routine
        img.list <- yr.all.winter
        
        ## img.list <- substr(yr.all.winter$ID, 4, 21)
        ## img.list$Row <- substr(img.list$Row, start=2, stop=4) ## changed for working on disk Jan'15
        ## img.list <- subset(img.list, subset=Path==147 & Row==46) ## done to fix the images in P143 R53
        ## img.list$Row <- paste("0",img.list$Row, sep="")
        ## fl.exists <- as.list(fl.exists[fl.exists=='LE71430531999306EDC01']) ## specific scenes
        ## fl.exists <- as.list(NULL)
        img.list <- missing.imgs(img.list, fl.exists)
        
        if(reprocess.lscorr==TRUE){
            img.list <- yr.all.winter
        }
        
        
        ## el <- is.element(img.list$ID,fl.exists) ## only select files which don't exist on the system
        ## img.list <- img.list[el, ]
        
        if(nrow(img.list)>0) {source("lscorr.R", echo=TRUE)} # uncomment to run the routine
    }

    ##----Run aggregates for NDVI
###   ## Decide which files should be processed for max.ndvi. Modified from earlier chunk
    
    if(run.ndviagg==TRUE){
        max.img.list <- yr.all.winter
        max.img.list$ID <- substr(max.img.list$ID, start=0, stop=13)
        if(!is.null(max.exists)){
            max.list <- missing.imgs(max.img.list, max.exists)
        } else {
            max.list <- max.img.list
        }
        if(reprocess.ndviagg==TRUE){
            max.list <- max.img.list
        }
        if(nrow(max.list)>0) {source("maxndvi.R", echo=TRUE)} # uncomment to run the routine
        ## calculate average ndvi
        avg.img.list <- yr.all.winter
        avg.img.list$ID <- substr(avg.img.list$ID, start=0, stop=13)
        if(!is.null(avg.exists)){
            avg.list <- missing.imgs(avg.img.list, avg.exists)
        } else {
            avg.list <- avg.img.list
        }
        if(reprocess.ndviagg==TRUE){
            avg.list <- avg.img.list
        }
        if(nrow(avg.list)>0) {source("avgndvi.R", echo=TRUE)} # uncomment to run the routine
    }

    if(run.ems==TRUE){
        ## calculate emissivity which is an input into LST
        ## NEEDS CHECKING HERE REGION SEEMS TO CHANGE
        ems.img.list <- yr.all.winter       
        ## ems.exists <- NULL ## this is to force updating images
        ## ems.img.list$ID <- substr(ems.img.list$ID, start=0, stop=21)
        if(!is.null(ems.exists)){
            ems.list <- missing.imgs(ems.img.list, ems.exists)
        } else {
            ems.list <- ems.img.list
        }
        if(reprocess.ems==TRUE){
            ems.list <- ems.img.list
        }
        if(nrow(ems.list)>0) {source("ems.R", echo=TRUE)} # uncomment to run the routine
    }

    if(run.lst==TRUE){
        ## calculate land surface temperature, min, max and avg
        lst.img.list <- yr.all.winter
        lst.exists <- NULL ## this is to force updating images
        ## to limit it to row 9
        ## lst.img.list <- lst.img.list[9,]
        ## lst.img.list$ID <- substr(lst.img.list$ID, start=0, stop=21)
        if(!is.null(lst.exists)){
            lst.list <- missing.imgs(lst.img.list, lst.exists)
        } else {
            lst.list <- lst.img.list
        }
        if(reprocess.lst==TRUE){
            lst.list <- lst.img.list
        }
        if(nrow(lst.list)>0) {source("lst.R", echo=TRUE)} # uncomment to run the routine
    }

    ##}
    
    ##  calculate average lst
    if(run.lstavg==TRUE){
        avg.lst.img.list <- yr.all.winter
        avg.lst.img.list$ID <- substr(avg.lst.img.list$ID, start=0, stop=13)
        if(!is.null(avg.lst.exists)){
            avg.lst.list <- missing.imgs(avg.lst.img.list, avg.lst.exists)
        } else {
            avg.lst.list <- avg.lst.img.list
        }
        if(reprocess.lstavg==TRUE){
            avg.lst.list <- avg.lst.img.list
        }
                                        # uncomment to run the routine
        if(nrow(avg.lst.list)>0) {
            source("avglst.R", echo=TRUE)
        }
    }
}



        ## 



        ## yr.all.slc.on <- na.omit(subset(all.slc.on, format.Date(Date, "%Y")==yrno, select=c(Path, Row, ID, Date)))
        ## yr.all.slc.off <- na.omit(subset(all.slc.off, format.Date(Date, "%Y")==yrno, select=c(Path, Row, ID, Date)))

        ## yr.slc.on.summer <- na.omit(subset(slc.on.summer, format.Date(Date, "%Y")==yrno, select=c(Path, Row, ID, Date)))
        ## yr.slc.off.summer <- na.omit(subset(slc.off.summer, format.Date(Date, "%Y")==yrno, select=c(Path, Row, ID, Date)))

        ## yr.slc.on.winter <- na.omit(subset(slc.on.winter, format.Date(Date, "%Y")==yrno, select=c(Path, Row, ID, Date)))
        ## yr.slc.off.winter <- na.omit(subset(slc.off.winter, format.Date(Date, "%Y")==yrno, select=c(Path, Row, ID, Date)))

        ## write.table(yr.all.summer, file=file.all.summer, row.names=FALSE,  quote=FALSE)
        ## write.table(yr.all.winter, file=file.all.winter, row.names=FALSE,  quote=FALSE)

        ## write.table(yr.all.slc.on, file=file.all.slc.on, row.names=FALSE,  quote=FALSE)
        ## write.table(yr.all.slc.off, file=file.all.slc.off, row.names=FALSE,  quote=FALSE)

        ## write.table(yr.slc.on.summer, file=file.slc.on.summer, row.names=FALSE,  quote=FALSE)
        ## write.table(yr.slc.off.summer, file=file.slc.off.summer, row.names=FALSE,  quote=FALSE)

        ## write.table(yr.slc.on.winter, file=file.slc.on.winter, row.names=FALSE,  quote=FALSE)
        ## write.table(yr.slc.off.winter, file=file.slc.off.winter, row.names=FALSE,  quote=FALSE)
                                        #}
