## NOTE: <gf.toar.dos4.LE71470472006321PFS00_B6_VCID_1> NEEDS TO BE
## REGENERATED AND LST CALCULATED AGAIN FOR TILES OF YEAR 2006. CORRUPTION IN FILE.

## Set mapset
execGRASS("g.mapset", mapset='pet', flags="quiet")

## first calculate emissivity for each scene using NDVI
## lst.list <- subset(lst.list, subset=ID=='LE71430541999306EDC01')
for(i in 1:nrow(lst.list)){
## i <- 29
    ## src.ems <- paste("ems.", lst.list$ID[i], sep="")
    src.tas <- paste("toar.dos4.", lst.list$ID[i], "_B6_VCID_1@l7corrected", sep="") 
    ##  replaced  ref with dos4 as the
    ## reflectance is to be black body corrected as per weng etal.
    out.lst <- paste("lst.", lst.list$ID[i], sep="")
    out.lst.cel <- paste("lst.cel.", lst.list$ID[i], sep="")
    ## execGRASS("g.region", raster=src.ems)
    ## check if resampling already done
    ## bilinear resampling for images before feb 25 2010
    if (lst.list$Date[i] < "2010-02-25"){
        execGRASS("g.mapset", mapset='l7corrected', flags="quiet")
        execGRASS("g.region", raster=src.tas, res='30')
        src.tas.60 <- paste(substrLeft(src.tas, 12), "_60", sep="")
        torename <- paste(src.tas,src.tas.60, sep=",")
        ## resample if not already done
        bilindone <- execGRASS("g.list", parameters=list(type='raster', pattern=src.tas.60), intern=TRUE)
        if(is.null(bilindone)){
            execGRASS("g.rename", flags="overwrite", raster=torename)
            execGRASS("r.resamp.interp", flags="overwrite", input=src.tas.60, output=src.tas)
            ## execGRASS("g.remove", flags="f", type='raster', name=src.tas.60)
        }
        execGRASS("g.mapset", mapset='pet', flags="quiet")
    }

    ## working out lst calcluations based on Weng et al., 2004
    ## lambda <- 11.5
    ## Tb <- src.tas
    ## sigma <- 1.38*10^-23
    ## h <- 6.626*10^-34
    ## c <- 2.998*10^8
    ## rho <- h*c/sigma
    ## varepsilon <- src.ems
    ## expr <- paste("LST.LE71430531999306EDC01 = ",c ," / ( 1 + ( 11.45 * ", c, " / 14380 ) * log(", a, "))", sep="")
    ##    kelvin = Tb/(1+(11.5*10^-6*(Tb/0.01438))*log(em))
    execGRASS("g.region", raster=src.tas, res='30')
    expr <- paste(out.lst," = ",src.tas ," / ( 1 + ( 11.5 * (", src.tas, " / 14380 )) * log(0.987))", sep="")
    ## 0.01438 originally, however wavelength (lambda) in in micro meters therefore it moves 6 decimals to the right
    ## note emissivity taken from snyder, 1998 not from image i.e.
    ## log(", src.ems, "))" replaced by log(0.987))"
    ## This is the value both for green grass and broadleafed forest
    ## Ref, pg 25 Snyder, W. C., Z. Wan, Y. Zhang, and Y.-Z. Feng (1998), Classification-based emissivity for land surface temperature measurement from space, International Journal of Remote Sensing, 19(14), 2753–2774.

    execGRASS("r.mapcalc", flags = "overwrite", expression=expr)
    ## celcius map
    expr <- paste(out.lst.cel, " = ", out.lst, " - 273.15", sep="")
    execGRASS("r.mapcalc", flags = "overwrite", expression=expr)

    ##---- Gap Filled ----
    
    pat.tas <- paste("gf.toar.dos4*", format(lst.list$Date[i], "%Y"), "*_B6_VCID_1", sep="") ## replaced dos4 with ref
    gf.tas.list <- execGRASS("g.list", parameters=list(type='raster',
                                            pattern=pat.tas, mapset='l7corrected'), intern=TRUE)
    out.gf.lst <- paste("gf.lst.", lst.list$ID[i], sep="")
    ## src.gf.ems <- paste("gf.ems.", lst.list$ID[i], sep="")
    src.gf.tas <- paste("gf.toar.dos4.", lst.list$ID[i], "_B6_VCID_1", sep="") ## replaced dos4 with ref
    out.gf.lst <- paste("gf.lst.", lst.list$ID[i], sep="")
    out.gf.lst.cel <- paste("gf.lst.cel.", lst.list$ID[i], sep="")
    ## execGRASS("g.region", raster=src.gf.ems)
        
    if(src.gf.tas %in% gf.tas.list){
        ## bilinear resampling for images before feb 25 2010
        if (lst.list$Date[i] < "2010-02-25"){
            execGRASS("g.mapset", mapset='l7corrected', flags="quiet")
            execGRASS("g.region", raster=src.gf.tas, res='30')
            src.gf.tas.60 <- paste(substrLeft(src.gf.tas, 12), "_60", sep="")
            torename <- paste(src.gf.tas,src.gf.tas.60, sep=",")
            ## resample if not already done
            bilindone <- execGRASS("g.list", parameters=list(type='raster', pattern=src.gf.tas.60), intern=TRUE)
            if(is.null(bilindone)){
                execGRASS("g.rename", flags="overwrite", raster=torename)
                execGRASS("r.resamp.interp", flags="overwrite", input=src.gf.tas.60, output=src.gf.tas)
                ## execGRASS("g.remove", flags="f", type='raster', name=src.gf.tas.60)
            }
            execGRASS("g.mapset", mapset='pet', flags="quiet")
        }
        ## execGRASS("g.mapset", mapset='pet')
        execGRASS("g.region", raster=src.gf.tas, res='30')
        expr <- paste(out.gf.lst," = ",src.gf.tas ," / ( 1 + ( 11.5 *  (", src.gf.tas, " / 14380 )) * log(0.987))", sep="")
        execGRASS("r.mapcalc", flags = "overwrite", expression=expr)
        ## celcius map
        expr <- paste(out.gf.lst.cel, " = ", out.gf.lst, " - 273.15", sep="")
        execGRASS("r.mapcalc", flags = "overwrite", expression=expr)
    } else {
        execGRASS("g.copy", flags=c("overwrite", "quiet"), raster=paste(out.lst, out.gf.lst, sep=","))
        execGRASS("g.copy", flags=c("overwrite", "quiet"), raster=paste(out.lst.cel, out.gf.lst.cel, sep=","))
    }
    print(paste("writing file number", i, "of", nrow(lst.list), ":", out.lst.cel, sep=" "))
}


