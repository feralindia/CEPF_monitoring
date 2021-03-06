## Script to derive ET using Zhang et. al., 2001.
## and calculate blue and green water
## inputs are the w (soil moisture) layers generated
## from LANDSAT and annual precipitation and potential evapotranspiration
## from from TRMM and MODIS respectively.
## We have rescaled TVDI to the 'w' parameter. The alternative approach is to
## get reference dry and wet pixel from known areas.
## This step should allow users to identify bounding box for specific regions.
## There are two potential sources of this information. The IFP physiognomy layer
## or Krishnaswamy et al., 2009 layers. Given that we need to rely on secondary information
## we suggest looking at KMTR for the wet evergreen reference class and and Mukurthi for the dry grassland class
## Source is IFP data. Considering the date of publication of this data, we will pick the values from 1999
## However, for simplicity sake, we can take the inverse of the TVDI to represent the w parameter.
## Analysis based on:
## Krishnaswamy, J. (2013), Assessing Canopy Processes at Large Landscape Scales in the
## Western Ghats Using Remote Sensing, in Treetops at Risk, pp. 289–294, Springer.
## and conceptual basis from:
## Zhang, L., W. R. Dawes, and G. R. Walker (2001),
## Response of mean annual evapotranspiration to vegetation changes
## at catchment scale, Water resources research, 37(3), 701–708.

##--- Load Libs
source("LoadLibs.R", echo=TRUE)
source("LoadFuncts.R", echo=TRUE)
##--- decide what routines to run
runBlue <- FALSE
runPropBlue <- TRUE

##--- organise the files---##

pat.trmm <- "*.trmm"
pat.modis <- "A*36*"
pat.w <- "gf.toar.w.*"
pat.median.w <- "gf.toar.median.w.*"

list.P <- execGRASS("g.list", type='raster', pattern=pat.trmm, mapset='trmm',  intern=TRUE)

list.pet <- execGRASS("g.list", type='raster', pattern=pat.modis, mapset='modis',  intern=TRUE)

list.w <- execGRASS("g.list", type='raster', pattern=pat.w, mapset='tvdi',  intern=TRUE)

years.w <- substr(list.w, start=20, stop=23)

yrs.w <- sort(unique(years.w))
subsetcols.w <- unique(substr(list.w, start=14, stop=16))
subsetrows.w <- unique(substr(list.w, start=17, stop=19))
rc.w <- unique(substr(list.w, start=14, stop=19))



##--select the relevant layers and tiles for final calculation
list.med.w <- execGRASS("g.list", type='raster', pattern="gf.toar.median.w.*", mapset='tvdi',  intern=TRUE)


##--get matching years for all datasets
execGRASS("g.mapset", mapset='tvdi')
for(i in 2: length(yrs.w)){
    ## list of maps for each year
    med.w.yr <- subset(list.med.w, subset=yrs.w[i]==
                           substr(list.med.w, start=24, stop=27))
    pet.yr <- subset(list.pet, subset=yrs.w[i]==
                         substr(list.pet, start=2, stop=5))
    P.yr <- subset(list.P, subset=yrs.w[i]==
                       substr(list.P, start=4, stop=7))
    
    if(length(P.yr)>0 & length(pet.yr)>0){
        pet.yr <- paste(pet.yr, "@modis", sep="")
        P.yr <- paste(P.yr, "@trmm", sep="")
        for(j in 1:length(med.w.yr)){
            if(runBlue==TRUE || runPropBlue==TRUE){
            w <- med.w.yr[j]
            execGRASS("g.region", raster=w, res='30')
            ## resample the modis and trmm to the landsat file region and resolution
            execGRASS("r.resamp.interp", flags="overwrite",
                      input=pet.yr, output='Eo', method='bilinear')
            pausenow(20)
            execGRASS("r.resamp.interp", flags="overwrite",
                      input=P.yr, output='P', method='bilinear') ## nearest gives junk
            pausenow(20)
            ## name the output rasters
        }
            suffix <- substr(w, start=18, stop=28)
            ET <- paste("ET.", suffix, sep="")
            Blue <- paste("Blue.", suffix, sep="")
            PropBlue <- paste("PropBlue.", suffix, sep="")
            if(runBlue==TRUE){
            
            expr <- paste(ET, " = P * 0.1* (1+(", w, " * Eo / P))/(1 + (", w, " * Eo / P) + (Eo / P)^-1)", sep="")
            ## See ftp://ftp.ntsg.umt.edu/pub/MODIS/NTSG_Products
            ## /MOD16/MOD16_global_evapotranspiration_description.pdf
            ## for description of the data and reason for the o.1 multiplication
            execGRASS("r.mapcalc", flags="overwrite", expression=expr)
            pausenow(20)
            
            expr <- paste(Blue, " = P - ", ET, sep="")
            execGRASS("r.mapcalc", flags="overwrite", expression=expr)
            pausenow(20)
        }
            if(runPropBlue==TRUE){
            expr <- paste(PropBlue, " = ", Blue,  "/P", sep="")
            execGRASS("r.mapcalc", flags="overwrite", expression=expr)
        }
            print(paste("Map", PropBlue,"written.", sep=" "))
        }
        print(paste("Tiles for year ", yrs.w[i], " created.", sep=""))
    }
}


