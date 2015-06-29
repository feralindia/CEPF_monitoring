## Script to do various forms of correction for images using existing GRASS libraries
## Import all files in a LS folder, needs to be put into a loop
## lsdatadir <- "/maps/LANDSAT/WGhats/143_53/"  ##  "/home/udumbu/rsb/tmp/" ## 
## dirlst <- dir(path=lsdatadir, pattern = "LE7*")
## Get file names and directory from the selimgs.R
## dirlist <- paste("/maps2/western_ghats/", img.list$Path, "_",  img.list$Row,"/",img.list$ID, sep="")
dirlist <- paste("/maps2/western_ghats/", img.list$Path, "_",  as.numeric(img.list$Row),"/",img.list$ID, sep="")
## Ensure mapset is correct
execGRASS("g.mapset",
          parameters=list(mapset='PERMANENT'))
## create new dataframe to hold image name and date
## <http://stackoverflow.com/questio qns/3642535/creating-an-r-dataframe-row-by-row>
##img.dts<- data.frame(scene=rep(NA, length(dirlist)), date=rep("", length(dirlist),
##                 stringsAsFactors=FALSE))   
img.dts <- data.frame(scene=character(0), date=character(0), stringsAsFactors=FALSE)
##for (i in 1: length(dirlist)){ ##uncomment to make it run through all directories.
for (n in 1:length(dirlist)) {
    ##     imgdir <- paste(dirlist[n], "/", sep="")
    imgdir <- dirlist[n]
    imgflst <- list.files(imgdir, pattern="*.TIF$")
    metfl <- list.files(imgdir, full.names=TRUE, pattern="*MTL.txt$")
    ## use pallelization here as it is the same path row
    for (o in 1:length(imgflst)){  ## replaced by foreach command
        imgflnme <-  c(paste("B", 1:5, sep=""), "B61", "B62", paste("B", 7:8, sep=""))
        execGRASS("r.in.gdal",
                  flags=c("o", "e", "overwrite"),
                  parameters=list(input=paste(imgdir, imgflst[o], sep="/"),
                      output=imgflnme[o]))
    }
    ## Set region to imported map
    execGRASS("g.region", raster='B1') ## res only for testing
    ## Top of atmosphere correction
    ## Script insists on all bands but we only need b3 and b4 for NDVI and
    ## 2, 3, 4, 5, and 6 (61 in LS7) for cloud assessment so create 0 value maps for others
    ## rmbands <- imgflnme[c(-1,-2,-3,-4,-5,-6,-8)] # get list of files to set to 0 to save processing time
    ## ## Loop to set the unwanted files to 0 value rasters
    ## ## Disabled for now probably can be deleted
    ## for (k in 1:length(rmbands)){
    ##     expr <- paste(rmbands[k], "=",rmbands[k],"*0", sep="")
    ##     execGRASS("r.mapcalc",
    ##               flags="overwrite",
    ##               expression=expr)
    ##}
    ##  Needs to be run with the -r flag for DN values (radiances).
    ## note cloud removal which requires reflectance not radiance (without -r flag).
    ## also note we are using reflectance at surface not at sensor with dark object subtraction - dos4

    ## The code for toar should be made multicored will speed up processing substantially
    ## fraw <- "overwrite"
    ## praw <- list(input_prefix='B', output_prefix='toar.ref.B', metfile=metfl, sensor='tm7')
    ## frad <- c("overwrite", "r")
    ## prad <- list(input_prefix='B', output_prefix='toar.rad.B', metfile=metfl, sensor='tm7')
    ## fdos <- "overwrite"
    ## pdos <- list(input_prefix='B', output_prefix='toar.dos4.B', metfile=metfl, sensor='tm7', method='dos4')

    ## flagsin <- c(fraw, frad, fdos)
    ## paramsin <- c(praw, prad, pdos)
    
    execGRASS("i.landsat.toar",
              flags=c("overwrite"),
              parameters=list(input='B', output='toar.ref.B', metfile=metfl, sensor='tm7')) ## radiance
    execGRASS("i.landsat.toar",
              flags=c("overwrite", "r"),
              parameters=list(input='B', output='toar.rad.B', metfile=metfl, sensor='tm7')) ## reflectance
    execGRASS("i.landsat.toar",
              flags=c("overwrite"),
              parameters=list(input='B', output='toar.dos4.B', metfile=metfl, sensor='tm7', method='dos4')) ## normalised reflectance. For thermal band this is at-surface temperature in Kelvin when done without normalisation.

    ## dos4 or dos3 are better. Dos3 might be better as it does a Rayleigh atmospheric correction. Dos 4 does a relative atmospheric correction which is also OK.
    ## ref: Song, Conghe, Curtis E. Woodcock, Karen C. Seto, Mary Pax Lenney, and Scott A. Macomber. ‘Classification and Change Detection Using Landsat TM Data: When and How to Correct Atmospheric Effects?’. Remote Sensing of Environment 75, no. 2 (2001): 230–44.

    dt <- execGRASS("i.landsat.toar",
                    flags=c("overwrite", "p"),
                    parameters=list(input='B', output='toar.dos4.B', metfile=metfl, sensor='tm7', 
                        lsatmet='date'), intern=TRUE)
    ## img <- substrLeft(imgdir, 1)
    dts <- substrRight(dt, 10)
    img.dts[n, ] <- c(imgdir,dts)
    gapmaskdir <- paste(imgdir, "/gap_mask", sep="")
    ## ## remove unwanted rasters
    ## rmtoarbands <- paste("toar.", rmbands, sep="") ## check this out
    ## rmrast <- c(rmbands, rmtoarbands)
    ## execGRASS("g.mremove",
    ##           flags=c("f"),
    ##           parameters=list(rast=rmrast))

    
    ## CL0UD COVER ASSESSMENT SHOULD BE DONE ON THE GAP FILLED RASTERS
    ## fillnodata.R does the gap-fill. Only to be run for images with the gapmask
    if(file.exists(gapmaskdir)){
        source("fillnodata.R", echo=TRUE)
    }

    execGRASS("g.region", raster='B1') 
    
    ## Cloud cover assessment
    ## On image without gap filling
    execGRASS("i.landsat.acca",
              flags=c("f", "s", "x", "2" , "overwrite"), ## added more options CHECK
              parameters=list(input='toar.ref.B', output='acca.B'))
    ## On image after gap filling
    if(length(list.files(imgdir, recursive = TRUE, pattern="GM_B1.TIF.gz"))>0){ 
        execGRASS("i.landsat.acca",
                  flags=c("f", "s", "x", "2", "overwrite"),
                  parameters=list(input='gf.toar.ref.B', output='gf.acca.B'))
    }
    
    ## rename the desired outputs to the correct name and move them to the correct mapset
    execGRASS("g.mapset",
              flags="c",
              parameters=list(mapset='l7corrected'))
    ## function to copy files
    cp.files <- function(x){
        execGRASS("g.copy",
                  flags="overwrite",
                  parameters=list(raster=x))
    }
    ##--- get names of each band
    bnd1 <- substrLeft(imgflst[1], 4)
    bnd2 <- substrLeft(imgflst[2], 4)
    bnd3 <- substrLeft(imgflst[3], 4)
    bnd4 <- substrLeft(imgflst[4], 4)
    bnd5 <- substrLeft(imgflst[5], 4)
    bnd61 <- substrLeft(imgflst[6], 4)
    bnd7 <- substrLeft(imgflst[8], 4)
    acca.bnd <- substrLeft(imgflst[1], 7)
    
    ##--- Copy normalised at surface DOS4  maps to corrected file
    ## -- note for thermal band no normalisation is done,
    ##-- i.e. ref and not dos4 is used
    toar.B1 <- paste("toar.dos4.", bnd1, sep="")
    toar.B2 <- paste("toar.dos4.", bnd2, sep="")
    toar.B3 <- paste("toar.dos4.", bnd3, sep="")
    toar.B4 <- paste("toar.dos4.", bnd4, sep="")
    toar.B5 <- paste("toar.dos4.", bnd5, sep="")
    toar.B61 <- paste("toar.ref.", bnd61, sep="") ## changed from dos4 to ref
    toar.B7 <- paste("toar.dos4.", bnd7, sep="")
    acca <- paste("acca.", acca.bnd, sep="")
    cpB1 <- paste("toar.dos4.B1@PERMANENT", toar.B1, sep=",") # chaged to reflectance (dos4) image
    cpB2 <- paste("toar.dos4.B2@PERMANENT", toar.B2, sep=",")
    cpB3 <- paste("toar.dos4.B3@PERMANENT", toar.B3, sep=",")
    cpB4 <- paste("toar.dos4.B4@PERMANENT", toar.B4, sep=",")
    cpB5 <- paste("toar.dos4.B5@PERMANENT", toar.B5, sep=",")
    cpB61 <- paste("toar.ref.B61@PERMANENT", toar.B61, sep=",") ## changed from dos4 to ref
    cpB7 <- paste("toar.dos4.B7@PERMANENT", toar.B7, sep=",")
    cpacca <- paste("acca.B@PERMANENT", acca, sep=",") # raw reflectance not normalised
    cp.rst<-c(cpB1, cpB2, cpB3, cpB4, cpB5, cpB61, cpB7, cpacca)
    lapply(cp.rst, cp.files)

    ##-- gopy gap filled images
    if(file.exists(gapmaskdir)){
        toar.B1 <- paste("gf.toar.dos4.", bnd1, sep="")
        toar.B2 <- paste("gf.toar.dos4.", bnd2, sep="")
        toar.B3 <- paste("gf.toar.dos4.", bnd3, sep="")
        toar.B4 <- paste("gf.toar.dos4.", bnd4, sep="")
        toar.B5 <- paste("gf.toar.dos4.", bnd5, sep="")
        toar.B61 <- paste("gf.toar.ref.", bnd61, sep="") ## use ref not dos4
        toar.B7 <- paste("gf.toar.dos4.", bnd7, sep="")
        acca <- paste("gf.acca.", acca.bnd, sep="")
        cpB1 <- paste("gf.toar.dos4.B1@PERMANENT", toar.B1, sep=",") # chaged to reflectance (dos4) image
        cpB2 <- paste("gf.toar.dos4.B2@PERMANENT", toar.B2, sep=",")
        cpB3 <- paste("gf.toar.dos4.B3@PERMANENT", toar.B3, sep=",")
        cpB4 <- paste("gf.toar.dos4.B4@PERMANENT", toar.B4, sep=",")
        cpB5 <- paste("gf.toar.dos4.B5@PERMANENT", toar.B5, sep=",")
        cpB61 <- paste("gf.toar.ref.B61@PERMANENT", toar.B61, sep=",") ## use ref not dos4
        cpB7 <- paste("gf.toar.dos4.B7@PERMANENT", toar.B7, sep=",")
        cpacca <- paste("gf.acca.B@PERMANENT", acca, sep=",") # raw reflectance not normalised
        cp.rst<-c(cpB1, cpB2, cpB3, cpB4, cpB5, cpB61, cpB7, cpacca)
        lapply(cp.rst, cp.files)
    }

    ## ---- NOTE
    ##--- Code below is good
    ##--- Commented out to save space
    
    ##--- Copy refelctance at sensor  maps to corrected file

    
    ## toar.B1 <- paste("toar.ref.", bnd1, sep="")
    ## toar.B2 <- paste("toar.ref.", bnd2, sep="")
    ## toar.B3 <- paste("toar.ref.", bnd3, sep="")
    ## toar.B4 <- paste("toar.ref.", bnd4, sep="")
    ## toar.B5 <- paste("toar.ref.", bnd5, sep="")
    ## toar.B61 <- paste("toar.ref.", bnd61, sep="")
    ## toar.B7 <- paste("toar.ref.", bnd7, sep="")
    
    ## cpB1 <- paste("toar.ref.B1@PERMANENT", toar.B1, sep=",") # chaged to reflectance (ref) image
    ## cpB2 <- paste("toar.ref.B2@PERMANENT", toar.B2, sep=",")
    ## cpB3 <- paste("toar.ref.B3@PERMANENT", toar.B3, sep=",")
    ## cpB4 <- paste("toar.ref.B4@PERMANENT", toar.B4, sep=",")
    ## cpB5 <- paste("toar.ref.B5@PERMANENT", toar.B5, sep=",")
    ## cpB61 <- paste("toar.ref.B61@PERMANENT", toar.B61, sep=",")
    ## cpB7 <- paste("toar.ref.B7@PERMANENT", toar.B7, sep=",")
    
    ## cp.rst<-c(cpB1, cpB2, cpB3, cpB4, cpB5, cpB61, cpB7)
    ## lapply(cp.rst, cp.files)

    
    ## ##--- Copy radiances maps to corrected file

    ## toar.B1 <- paste("toar.rad.", bnd1, sep="")
    ## toar.B2 <- paste("toar.rad.", bnd2, sep="")
    ## toar.B3 <- paste("toar.rad.", bnd3, sep="")
    ## toar.B4 <- paste("toar.rad.", bnd4, sep="")
    ## toar.B5 <- paste("toar.rad.", bnd5, sep="")
    ## toar.B61 <- paste("toar.rad.", bnd61, sep="")
    ## toar.B7 <- paste("toar.rad.", bnd7, sep="")
    
    ## cpB1 <- paste("toar.rad.B1@PERMANENT", toar.B1, sep=",") # chaged to reflectance (rad) image
    ## cpB2 <- paste("toar.rad.B2@PERMANENT", toar.B2, sep=",")
    ## cpB3 <- paste("toar.rad.B3@PERMANENT", toar.B3, sep=",")
    ## cpB4 <- paste("toar.rad.B4@PERMANENT", toar.B4, sep=",")
    ## cpB5 <- paste("toar.rad.B5@PERMANENT", toar.B5, sep=",")
    ## cpB61 <- paste("toar.rad.B61@PERMANENT", toar.B61, sep=",")
    ## cpB7 <- paste("toar.rad.B7@PERMANENT", toar.B7, sep=",")

    ## cp.rst<-c(cpB1, cpB2, cpB3, cpB4, cpB5, cpB61, cpB7)
    ## lapply(cp.rst, cp.files)

##---END OF COMMENTED OUT CODE

    
    ##--------------- run NDVIs and save to new mapset ---------------
    ## first create an inverse mask from the cloud layer
    ## I'll use all the categories of clouds and shadows
    execGRASS("g.mapset", mapset='PERMANENT')

    ## It makes sense to do this on the gap filled rasters replacing acca.B with gf.acca.B
    ## Change if you want to run this on SLC off images.
    ## Note that if slc is on (scene prior to 2003) it will pick original image
    
    if(file.exists(gapmaskdir)){
        execGRASS("g.region", raster='gf.toar.dos4.B4') 
        execGRASS("r.mask",
                  flags=c("i", "overwrite"),
                  parameters=list(raster='gf.acca.B@PERMANENT'))
        ## generate the ndvi
        expr.gf <- "gf.toar.ndvi=1.0*(gf.toar.dos4.B4-gf.toar.dos4.B3)/(gf.toar.dos4.B4+gf.toar.dos4.B3)"
        execGRASS("r.mapcalc",
                  flags="overwrite",
                  expression=expr.gf)
        execGRASS("g.mapset",
                  flags="c",
                  parameters=list(mapset='ndvi'))
        gf.toar.ndvi.bnd <- paste("gf.toar.ndvi.", substrLeft(imgflst[1], 7), sep="")
        cpgftoarndvi <- paste("gf.toar.ndvi@PERMANENT", gf.toar.ndvi.bnd, sep=",")
        execGRASS("g.copy",
                  flags="overwrite",
                  parameters=list(raster=cpgftoarndvi))
    }
    execGRASS("g.mapset",
              parameters=list(mapset='PERMANENT'))
    
    execGRASS("r.mask",
              flags=c("i", "overwrite"),
              parameters=list(raster='acca.B@PERMANENT'))
    
    
    ## generate the ndvi for the corrected and uncorrected image
    ## expr <- "ndvi=1.0*(B4-B3)/(B4+B3)"
    ## execGRASS("r.mapcalc",
    ##           flags="overwrite",
    ##           expression=expr)
    expr <- "toar.ndvi=1.0*(toar.dos4.B4-toar.dos4.B3)/(toar.dos4.B4+toar.dos4.B3)"
    execGRASS("r.mapcalc",
              flags="overwrite",
              expression=expr)
    ## move to the relevant mapset
    execGRASS("g.mapset",
              parameters=list(mapset='ndvi'))
    ## copy the relevant files to the correct names
    ##    ndvi.bnd <- paste("ndvi.", substrLeft(imgflst[1], 7), sep="")
    toar.ndvi.bnd <- paste("toar.ndvi.", substrLeft(imgflst[1], 7), sep="")
    ##  cpndvi <- paste("ndvi", ndvi.bnd, sep=",")
    cptoarndvi <- paste("toar.ndvi@PERMANENT", toar.ndvi.bnd, sep=",")
    ##    execGRASS("g.copy",
    ##             flags="overwrite",
    ##            parameters=list(raster=cpndvi))

    execGRASS("g.copy",
              flags="overwrite",
              parameters=list(raster=cptoarndvi))
    ## remove the mask from mapset ndvi
    ## execGRASS("r.mask",
    ##           flags="r")
    ## Clear up permanent mapset
    execGRASS("g.mapset",
              parameters=list(mapset='PERMANENT'))
    ## remove the mask
    execGRASS("r.mask",
              flags="r")
    ## remove all maps
    execGRASS("g.remove",
              flags="f",
              parameters=list(type='raster', pattern='*'))
    ## Some error prevents the gf.acca from being removed --force removal
    ## execGRASS("g.remove",
    ##           flags = "f", parameters = list(type='raster', raster='acca.B@PERMANENT,gf.acca.B@PERMANENT'))
    
}



