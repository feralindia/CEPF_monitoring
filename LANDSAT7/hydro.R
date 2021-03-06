##----Script to calculate green (ET) and blue (surface/sub-surface) water using RS routines in GRASS7----##
library(spgrass6)
## library(landsat)
library(timeDate)
## compare results with the report and data here: http://solar.geography.hawaii.edu/downloads.html:

execGRASS("g.mapset", parameters = list(mapset='pet'))
execGRASS("g.region", parameters = list(raster='toar.dos4.LE71430531999306EDC01_B1@l7corrected'))

## get metadata for images
metin <- execGRASS("r.info", flags = c("h", "quiet"),
                   parameters = list(map='toar.dos4.LE71430531999306EDC01_B1@l7corrected'), intern = TRUE)
aqdt <- metin[9]
aqdt <- substr(aqdt, start=45, stop=54)
tdobj <- as.timeDate(aqdt, zone="Asia/Calcutta")
doy <- dayOfYear(tdobj)
doy <- as.double(doy)
aqtm <- metin[9]
aqtm <- substr(aqtm, start=57, stop=62)
loctm <- as.numeric(aqtm) + 5.5
azi <- metin[13]
azi <- substr(azi, start=55 , stop=63 )
zen <- substr(metin[13], start=45, stop=52)

execGRASS("r.latlong", flags="overwrite",
          parameters=list(input='acca.LE71430531999306EDC01@l7corrected', output='lat.E71430531999306EDC01'))
execGRASS("r.latlong", flags=c("overwrite", "l"),
          parameters=list(input='acca.LE71430531999306EDC01@l7corrected', output='lon.E71430531999306EDC01'))

### r.sun ## reqd by i.eb.netrad for: surface radiance (glob_rad) which is elevation corrected, 
## use r.mapcalc and this <http://www.yale.edu/ceo/Documentation/Landsat_DN_to_Kelvin.pdf> for surface temperature calculations
## also LANDSAT package can be used as per <http://www.hakimabdi.com/20111030/estimating-land-surface-temperature-from-landsat-thermal-imagery/>

## base reference is here <http://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/20090027884.pdf>
execGRASS("i.albedo", flags=c('l','c', 'overwrite'),
           parameters=list(input='toar.dos4.LE71430531999306EDC01_B1@l7corrected,toar.dos4.LE71430531999306EDC01_B2@l7corrected,toar.dos4.LE71430531999306EDC01_B3@l7corrected,toar.dos4.LE71430531999306EDC01_B4@l7corrected,toar.dos4.LE71430531999306EDC01_B5@l7corrected,toar.dos4.LE71430531999306EDC01_B7@l7corrected', output='albedo.LE71430531999306EDC01')) ## requd by i.eb.netrad for: albedo

### i.albedo -l --overwrite --verbose input=toar.dos4.LE71430531999306EDC01_B1@l7corrected,toar.dos4.LE71430531999306EDC01_B2@l7corrected,toar.dos4.LE71430531999306EDC01_B3@l7corrected,toar.dos4.LE71430531999306EDC01_B4@l7corrected,toar.dos4.LE71430531999306EDC01_B5@l7corrected,toar.dos4.LE71430531999306EDC01_B7@l7corrected output=albedo.E71430531999_ond

## r.slope.aspect --overwrite elevation=ASTERdem@PERMANENT slope=ASTERslope aspect=ASTERaspect  ## only run once
## r.shaded.relief --overwrite input=ASTERdem@PERMANENT output=ASTERshrel ## only run once

## Note that r.sun is not needed. It takes a long time and should be ignored unless required for other models
## create horizon file to reduct time for running r.sun, values from r.sun manual
## r.horizon --overwrite elevation=ASTERdem@terrain step=30 bufferzone=200 maxdistance=5000 output=horiz
###  execGRASS("r.horizon", flags = "overwrite", parameters = list(elevation='ASTERdem@terrain', step=30, bufferzone=200, maxdistance=5000, output='horiz'))

### execGRASS("r.sun", flags=c("overwrite"),
###           parameters=list(elevation='ASTERdem@terrain', linke_value=1.5, day=doy, aspect='ASTERaspect@terrain', slope='ASTERslope@terrain',  horizon_basename='horiz', horizon_step=30, refl_rad='refl_rad.LE71430531999306EDC01@pet', glob_rad='glob_rad.LE71430531999306EDC01@pet')) ## using minimal inputs/outputs based on r.sun manual. Note Linke value for december and rural areas used
## r.sun --overwrite elevation=ASTERdem@terrain aspect=ASTERaspect@terrain slope=ASTERslope@terrain linke_value=1.5 albedo=albedo.LE71430531999306EDC01@pet refl_rad=refl_rad.LE71430531999306EDC01@pet glob_rad=glob_rad.LE71430531999306EDC01@pet day=305

execGRASS("i.emissivity", flags=c("overwrite"),
           parameters=list(input='toar.ndvi.LE71430531999306EDC01@ndvi', output='emiss.LE71430531999306EDC01@pet')
           ) ## define use input from lscorr and define emmis
## i.emissivity --overwrite input=toar.ndvi.LE71430531999306EDC01@ndvi output=emmis.LE71430531999306EDC01@pet

## the toar module does this automatically. Use the dos4 corrected image
## convert band 61 to radiances at sensor or 
## expr <- "rad=((17.0 - 0.) / (255. - 1.))*(B61 - 1.) + 0."
## execGRASS("r.mapcalc",
##           flags="overwrite",
##           expression=expr)
## ## convert to kelvin
## expr <- "tempk=1282.71 / log(666.09 / rad + 1.)"

## execGRASS("r.mapcalc",
##           flags="overwrite",
##           expression=expr)

## ------- Get constants for the image for i.eb.netrad and generate maps
## values to parameterise i.eb.netrad
## tsw=0.7, dtair or dT=5.0
##r.info -h map=toar.dos4.LE71430531999306EDC01_B1@l7corrected
## expressions for r.mapcalc
## land surface temperature from at-sensor-temperature
## simple description on <http://fromgistors.blogspot.com/2014/01/estimation-of-land-surface-temperature.html>
## where a is the emissivity raster and b is the brightness temperature raster
## centre wavelength Landsat 4, 5, and 7, band 6: 11.45
## center wavelenth LS8, B10, 10.08, LS8, B11: 12

## Taken from GRASS book (neteler and mitasova)x
a <- "emiss.LE71430531999306EDC01@pet" # emissivity layer
b <- "toar.rad.LE71430531999306EDC01_B6_VCID_1" # radiance at sensor

## for temperature at sensor <http://landsathandbook.gsfc.nasa.gov/data_prod/prog_sect11_3.html>
## using from GRASS book:
K1 <- 666.09
K2 <- 1282.71
expr <- paste("TAS.LE71430531999306EDC01 = ", K2, "/ log(", K1, "/", b, " + 1.0)", sep="")
execGRASS("r.mapcalc", flags = "overwrite", expression=expr)
c <- "TAS.LE71430531999306EDC01" # surface temperature at sensor (uncorrected)
## NOTE toar.dos4 on a thermal band also gives TAS. See explanation in GRASS book
## eqn (6) Weng et al., 2004
## also see eqn 1.5 in J. Mallick et al., 2012
expr <- paste("LST.LE71430531999306EDC01 = ",c ," / ( 1 + ( 11.45 * ", c, " / .01438 ) * log(", a, "))", sep="")
execGRASS("r.mapcalc", flags = "overwrite", expression=expr)
expr <- "LSTcel.LE71430531999306EDC01 = LST.LE71430531999306EDC01 - 273.15"
execGRASS("r.mapcalc", flags = "overwrite", expression=expr) # convert to celsius


expr <- paste("doy_rst=", doy, sep="")
execGRASS("r.mapcalc", flags = "overwrite", expression=expr)

expr <- paste("loctm_rst=", loctm, sep="")
execGRASS("r.mapcalc", flags = "overwrite", expression=expr)

expr <- paste("azi_rst=", azi, sep="")
execGRASS("r.mapcalc", flags = "overwrite", expression=expr)

expr <- paste("zen_rst=", zen, sep="")
execGRASS("r.mapcalc", flags = "overwrite", expression=expr)

execGRASS("r.mapcalc", flags = "overwrite", expression="dT_rst=5.0") ## should this be changed to 5 less than LST
## This is a serious assumption, should try and resolve equation
## eqn 30 from Bastiaanssen, W. G. M., M. Menenti, R. A. Feddes, and A. A. M. Holtslag. ‘A Remote Sensing Surface Energy Balance Algorithm for Land (SEBAL). 1. Formulation’. Journal of Hydrology 212 (1998): 198–212.
## get atmospheric temperature
## from Sobrino et al., 2004 eqn. 3
## also see Liu et al., 2007 eqn. 8
## and Qin et al., 2001 eqn.32b
## Problem arises as T0 (near surface atmospheric temperature as measured at 2m height)
## is not avialable for most cases
## Wloczyk et al, 2011 have a NDVI based approach which will probably work best.

execGRASS("r.mapcalc", flags = "overwrite", expression="tsw_rst=0.7") ## one way transmissivity as per manual
execGRASS("r.mapcalc", flags = "overwrite", expression="transmiss1w_rst=1.0") ## default is 1.0 for one way transmissivity
## as in Bastiaanssen, et al., 1998.
execGRASS("r.mapcalc", flags = "overwrite", expression="t0dem = TAS.LE71430531999306EDC01 + (ASTERdem@terrain * 0.627 / 100)") ## altiude corrected temperature also called temperature at mean sea level (from i.eb.hsebal01 manual)

execGRASS("i.eb.netrad", flags = ("overwrite"),
          parameters = list(
              albedo='albedo.LE71430531999306EDC01',
              ndvi='toar.ndvi.LE71430531999306EDC01@ndvi',
              temperature='toar.dos4.LE71430531999306EDC01_B6_VCID_1@l7corrected', # LST.LE71430531999306EDC01@pet'?
              localutctime='loctm_rst',
              temperaturedifference2m='dT_rst',
              emissivity='emiss.LE71430531999306EDC01@pet',
              transmissivity_singleway='transmiss1w_rst', # replaced tsw_rst
              dayofyear='doy_rst',
              sunzenithangle='zen_rst', 
              output='netrad5.LE71430531999306EDC01'
              ))

## Use example here <http://www.ibiblio.org/pub/packages/gis/grass/manuals/html70_user/i.evapo.pm.html>
## also see <http://courses.neteler.org/will-the-sun-shine-on-us/>
## NOTES

## Net solar radiation map in MJ/(m2*h) can be computed from the combination of the r.sun , run in mode 1, and the r.mapcalc commands.
## The sum of the three radiation components outputted by r.sun (beam, diffuse, and reflected) multiplied by the Wh to Mj conversion factor (0.0036) and optionally by a clear sky factor [0-1] allows the generation of a map to be used as an NSR input for the i.evapo.PM command.
## example:

## r.sun -s elevin=dem aspin=aspect slopein=slope lin=2 albedo=alb_Mar incidout=out beam_rad=beam diff_rad=diffuse refl_rad=reflected day=73 time=13:00 dist=100;
## r.mapcalc 'NSR=0.0036*(beam+diffuse+reflected)';
## Chemin was clear that r.sun and mapcalc give a better result than using i.eb.netrad.

## r.sun --overwrite elevation=ASTERdem@terrain aspect=ASTERaspect@terrain slope=ASTERslope@terrain albedo=albedo.LE71430531999306EDC01@pet incidout=inciangle.LE71430531999306EDC01 beam_rad=beam_irra.LE71430531999306EDC01 diff_rad=diffuse_irra.LE71430531999306EDC01 refl_rad=refl_irra.LE71430531999306EDC01 day=305 time=4.972710.4727 distance_step=100

## execGRASS("r.sun", flags = c("overwrite"),
##           parameters = list(elevation='ASTERdem@terrain',
##               aspect='ASTERaspect@terrain',
##               slope='ASTERslope@terrain',
##               albedo='albedo.LE71430531999306EDC01@pet',
##               incidout='inciangle.LE71430531999306EDC01',
##               beam_rad='beam_irra.LE71430531999306EDC01',
##               diff_rad='diffuse_irra.LE71430531999306EDC01',
##               refl_rad='refl_irra.LE71430531999306EDC01',
##               day=doy,
##               time=loctm,
##               distance_step=1))
## calculate Net rad from r.sun, note this is giving absurd values needs to be rechecked.
## expr <- "netrad.LE71430531999306EDC01=0.0036*(beam_irra.LE71430531999306EDC01+diffuse_irra.LE71430531999306EDC01+refl_irra.LE71430531999306EDC01)"
## execGRASS("r.mapcalc", flags = "overwrite", expression=expr)

execGRASS("i.eb.soilheatflux", flags = ("overwrite"),
          parameters=list(
              albedo='albedo.LE71430531999306EDC01@pet',  #albedo.E71430531999_ond@pet
              ndvi='toar.ndvi.LE71430531999306EDC01@ndvi',
              temperature='toar.dos4.LE71430531999306EDC01_B6_VCID_1@l7corrected',  #LST.LE71430531999306EDC01@pet',
              netradiation='netrad5.LE71430531999306EDC01@pet',
              localutctime='loctm@pet',
              output='soilhf.LE71430531999306EDC01'
              ))

## Potential evapotranspiration
## get data from r.latlong

## i.evapo.potrad -r -d --overwrite albedo=albedo.LE71430531999306EDC01@pet temperature=LST.LE71430531999306EDC01@pet latitude=lat.E71430531999306EDC01@pet dayofyear=doy_rst@pet transmissivitysingleway=<required> waterdensity=1005.0 slope=ASTERslope@terrain aspect=ASTERaspect@terrain output=pet.E71430531999306EDC01 rnetd=rnetd.E71430531999306EDC01

execGRASS("i.evapo.potrad", flags = c("r", "overwrite"), ## slope/aspect correction giving "d" flag causing errors.
          parameters=list(
              albedo='albedo.LE71430531999306EDC01@pet',
              temperature='toar.dos4.LE71430531999306EDC01_B6_VCID_1@l7corrected', ##not LST.LE71430531999306EDC01@pet
              latitude='lat.E71430531999306EDC01@pet',
              dayofyear='doy_rst',
              transmissivitysingleway='transmiss1w_rst@pet', # defalut value of 1.0
              waterdensity=1005.0,
              slope='ASTERslope@terrain',
              aspect='ASTERaspect@terrain',
              atmosphericemissivity=0.845,
              output='pet.E71430531999306EDC01',
              rnetd='rnetd.E71430531999306EDC01'
                  ))


## calculate moment roughness length and MR heat transport
execGRASS("i.eb.z0m", flags = ("overwrite"),
          parameters = list(
              input='toar.ndvi.LE71430531999306EDC01@ndvi',
              output='z0m.LE71430531999306EDC01',
              z0h='z0h.LE71430531999306EDC01'
          ))


                  ### To be worked on from here


## Need to identify wet and dry pixels. As per  Also need to check with JK whether other assumptions are reasonable.

i.eb.hsebal01 -c netradiation=netrad5.LE71430531999306EDC01@pet soilheatflux=soilhf.LE71430531999306EDC01@pet aerodynresistance=z0m.LE71430531999306EDC01@pet temperaturemeansealevel=t0dem@pet frictionvelocitystar=0.32407 vapourpressureactual=1.511 row_wet_pixel=1100322.53932 column_wet_pixel=786849.481003 row_dry_pixel=1100292.95623 column_dry_pixel=786516.397335 output=senshf.LE71430531999306EDC01

 ## root zone soil moisture or "w" parameter in the Zhang, Walker balance equation.
i.eb.evapfr -m netradiation=netrad5.LE71430531999306EDC01@pet soilheatflux=soilhf.LE71430531999306EDC01@pet sensibleheatflux=senshf.LE71430531999306EDC01@pet evaporativefraction=evapfrac.LE71430531999306EDC01 soilmoisture=rzsoilmoisture.LE71430531999306EDC01

## Evapotranspiration map
i.eb.eta --overwrite netradiationdiurnal=rnetd.E71430531999306EDC01@pet evaporativefraction=evapfrac.LE71430531999306EDC01@pet temperature=toar.dos4.LE71430531999306EDC01_B6_VCID_1@l7corrected output=et_sebal.E71430531999306EDC01

