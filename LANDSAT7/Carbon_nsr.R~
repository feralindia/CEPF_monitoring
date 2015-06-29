##---- routine to generate nsr----##
##-- Pull in MTL data

## head(imglist, n=20)
## note i==6 threw a segfault. Needs to be redone: 21May15.
execGRASS("g.mapset", mapset='npp')
for(i in 290 : nrow(imglist)){
    ## i <- 10
    mtldet <-  read.csv(file=imglist$mtlpath[i], sep="=", strip.white=TRUE)
    names(mtldet)
    mtldet <- subset(mtldet, subset=GROUP != "GROUP")
    mtldet <- subset(mtldet, subset=GROUP != "END_GROUP")
    mtldet <- subset(mtldet, subset=GROUP != "END")
    row.names(mtldet) <- mtldet$GROUP
    names(mtldet) <- NULL
    ##-- Transpose
    mtlrow <- t(mtldet)
    mtlrow <- as.data.frame(mtlrow)
    mtlrow <- mtlrow[2,]
    ##-- Pull in the data from the MTL file
    doy <- as.timeDate(mtlrow$DATE_ACQUIRED, zone="Asia/Calcutta")
    year <- as.numeric(substr(mtlrow$DATE_ACQUIRED, start=0, stop=4))
    doy <- as.double(dayOfYear(doy))
    ## the time calculation is fucked up so do this by brute force
    hr <- as.numeric(substr(mtlrow$SCENE_CENTER_TIME, start=1, stop=2))
    min <- as.numeric(substr(mtlrow$SCENE_CENTER_TIME, start=4, stop=5))
    sec <-  as.numeric(substr(mtlrow$SCENE_CENTER_TIME, start=7, stop=8))
    dechr <- hr+ (min*100/60 + sec*1/60)/100 + 5.5

    ##--name maps
    ##-- input maps
    ndvi <- paste("gf.toar.ndvi.", imglist$imgid[i], sep="")
    if(year<2003){
        b1 <- paste("toar.dos4.", imglist$imgid[i],"_B1@l7corrected", sep="")
        b2 <- paste("toar.dos4.", imglist$imgid[i],"_B2@l7corrected", sep="")
        b3 <- paste("toar.dos4.", imglist$imgid[i],"_B3@l7corrected", sep="")
        b4 <- paste("toar.dos4.", imglist$imgid[i],"_B4@l7corrected", sep="")
        b5 <- paste("toar.dos4.", imglist$imgid[i],"_B5@l7corrected", sep="")
        b7 <- paste("toar.dos4.", imglist$imgid[i],"_B7@l7corrected", sep="")
    }else{
        b1 <- paste("gf.toar.dos4.", imglist$imgid[i],"_B1@l7corrected", sep="")
        b2 <- paste("gf.toar.dos4.", imglist$imgid[i],"_B2@l7corrected", sep="")
        b3 <- paste("gf.toar.dos4.", imglist$imgid[i],"_B3@l7corrected", sep="")
        b4 <- paste("gf.toar.dos4.", imglist$imgid[i],"_B4@l7corrected", sep="")
        b5 <- paste("gf.toar.dos4.", imglist$imgid[i],"_B5@l7corrected", sep="")
        b7 <- paste("gf.toar.dos4.", imglist$imgid[i],"_B7@l7corrected", sep="")
    }
    ##-- output maps
    albedo <- paste("gf.toar.albedo.", imglist$imgid[i], sep="")
    alb.in <- paste(b1,b2,b3,b4,b5,b7, sep=",")
    lat <- paste("gf.toar.lat.", imglist$imgid[i], sep="")
    lon <- paste("gf.toar.lon.", imglist$imgid[i], sep="")
    nsr <- paste("gf.toar.nsr.", imglist$imgid[i], sep="")
    ## Get Region
    execGRASS("g.region", raster=b1, flags="p")
    ## Get albedo, lat and lon
    execGRASS("i.albedo", flags=(c("l",  "overwrite")),  input=alb.in, output=albedo, intern=TRUE)
    print(paste(albedo,"created", sep=" "))
    
    execGRASS("r.latlong", flags=(c("l","overwrite")), input=b1, output=lon, intern=TRUE)
    print(paste(lon,"created", sep=" "))
    pausenow(20)
    
    execGRASS("r.latlong", flags="overwrite", input=b1, output=lat, intern=TRUE)
    print(paste(lat,"created", sep=" "))
    pausenow(20)
    
    ##-- get netrad
    execGRASS("r.sun", flags="overwrite", elevation='ASTERdem@terrain', aspect='ASTERaspect@terrain', slope='ASTERslope@terrain', albedo=albedo, lat=lat, long=lon, incidout='out', beam_rad='beam', diff_rad='diffuse', refl_rad='reflected', day=doy, time=dechr, intern=TRUE)
    print("NSR input created")

    pausenow(20)
    
    ##-- get nsr
    nsr.exp <- paste(nsr," = 0.0036 * (beam + diffuse + reflected)")
    ##   nsr.exp <- paste(nsr," = float(beam + diffuse + reflected)")
    execGRASS("r.mapcalc", flags="overwrite", expression=nsr.exp, intern=TRUE)
    print(paste("NSR map in MJ/(m2*h)", nsr, "written", sep=" "))
    ##-- clean up
    to.remove <- paste(lat, lon, albedo, "beam", "diffuse", "reflected", sep=",")
    execGRASS("g.remove", type='raster', name=to.remove, flags="f", intern=TRUE)
    print("Temporary files deleted", sep="")
}


