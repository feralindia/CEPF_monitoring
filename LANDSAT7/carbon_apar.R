
ndvi.gf.list <- paste("gf.toar.ndvi.", imglist$imgid, sep="")
ndvi.nogf.list <- paste("toar.ndvi.", imglist$imgid, sep="")
ndvi.year <- substr(ndvi.gf.list, start=23, stop=26)
nsr.list <- paste("gf.toar.nsr.", imglist$imgid, sep="")
apar.list <- paste("gf.toar.apar.", imglist$imgid, sep="")
ndvi.id <- substrRight(ndvi.gf.list, 21)
nsr.id <- substrRight(nsr.list, 21)
for(i in 1:length(imglist$imgid)){
    if(ndvi.id[i]==nsr.id[i]){
        if(ndvi.year[i]<2003){
            ndvi.in <- paste(ndvi.nogf.list[i], "@ndvi", sep="")
        } else {
            ndvi.in <- paste(ndvi.gf.list[i], "@ndvi", sep="")}
        nsr.in <- paste(nsr.list[i], "@npp", sep="")
        apar.expr <- paste(apar.list[i],"= 0.45 *", ndvi.in," * ", nsr.in, sep=" ")
        execGRASS("g.region", raster=nsr.in, res='30')
        execGRASS("r.mapcalc", expression=apar.expr, flags="overwrite")
    }
    print(paste("Map", i, "of", length(imglist$imgid), ": ", apar.list[i], "generated", sep=" "))
}
