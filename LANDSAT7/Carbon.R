## Script to calculate net radiation from LANDSAT images
## Based on method described in i.evapo.pm
## r.sun -s elevin=dem aspin=aspect slopein=slope lin=2 albedo=alb_Mar incidout=out beam_rad=beam diff_rad=diffuse refl_rad=reflected day=73 time=13:00 dist=100;
## r.mapcalc "NSR = 0.0036 * (beam + diffuse + reflected)"
## Calculate FAPAR for entire region
## Resources: http://fapar.jrc.ec.europa.eu/Home.php,
## ALL THESE NEED TO BE PUT INTO A LOOP AND NAMES STANDARDISED BASED ON INPUT MAPS
##--function pausenow to pause between commands
##-- Load libraries

source("LoadLibs.R", echo=TRUE)
##-- Load Functions
source("LoadFuncts.R", echo=TRUE)
##-- this works in the npp mapset
execGRASS("g.mapset", mapset='npp')
imglist <-execGRASS("g.list", type='raster', pattern='toar.dos4.*_B3', mapset='l7corrected', intern=TRUE)
imglist <- as.data.frame(imglist)
names(imglist) <- "imgid"
imglist$imgid <- substr(imglist$imgid, start=11, stop=31)
imglist$path <- substr(imglist$imgid, start=4, stop=6)
imglist$row <- substr(imglist$imgid, start=8, stop=9)
imglist$fldr <- paste(imglist$path, imglist$row, sep="_")
imglist$mtlfnme <- paste(imglist$imgid, "_MTL.txt", sep="")
imglist$mtlpath <- paste("/maps2/western_ghats/", imglist$fldr, "/", imglist$imgid, "/", imglist$imgid, "_MTL.txt", sep="")

source("Carbon_nsr.R", echo=TRUE)

source(("Carbon_apar.R", echo=TRUE)
