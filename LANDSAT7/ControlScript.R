
##-----------Script to control all routines---------------##
##-- Load Libraries


source("LoadLibs.R", echo=TRUE)
##-- Load Functions
source("LoadFuncts.R", echo=TRUE)
##-----------Need to define all names of input/output files here----------##

res.path <- "/home/pambu/rsb/OngoingProjects/CEPF_monitoring/rdata/results/"
gapfilldir <- "/home/pambu/rsb/OngoingProjects/CEPF_monitoring/rdata/gapfill/"

##---Decide which routines are to be run:

run.lscorr <- FALSE
run.ndviagg <- FALSE
run.ems <- FALSE
run.lst <- FALSE
run.lstavg <- FALSE

##--- Decide whether data is to be re-processed
##-- This sets the existing images to NULL and re-calculate
##-- the entire process again. Use with caution
reprocess.lscorr <- FALSE
reprocess.ndviagg <- FALSE
reprocess.ems <- FALSE
reprocess.lst <- FALSE
reprocess.lstavg <- FALSE
    ##-------Child routines are:
source("chekimgs.R", echo=TRUE) # create list of complete images
source("selimgs.R", echo=TRUE)
## select images based on dates, organise the files for subsequent processing
##--- Note selimgs.R calls lscorr.R and maxndvi.R. StackSlope.R is an independent script as of now.

##-- calculation of tvdi
run.tvdi1 <- FALSE ## To get parameters for TVDI
run.tvdi2 <- FALSE  ## To derive TVDI

if(run.tvdi1==TRUE){
    source("tvdi.R", echo=FALSE)
}

if(run.tvdi2==FALSE){
    source("tvdi2.R", echo=FALSE)
}
    
