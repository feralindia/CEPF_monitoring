#!/bin/bash
# Modify the line above to the location of your BASH interpreter.
#Input and output file names in the prm file are ignored during batch-processing
#
#
#
# Make a list of dates for processing
HDFFILES=$(ls *.hdf)
#Loop through the number of dates
for FILES in $HDFFILES
do
# Collect all MOD15 HDF files for a specific date

# Write these to a text file
echo $HDFFILES > mosaicinput.txt
# Run mrt mosaic and write output to HDF file (extension .hdf!)
#mrtmosaic -i mosaicinput.txt -o mosaic_tmp.hdf
# Call resample. Values for projection parameters are derived
# from the prm-file that was obtained using ModisTool. Input and
# output are specified using the -i and -o options.
resample -p modis.prm -i $FILES -o $FILES.tif
done

##renaming the file#### first step is to select characters.And then combine them.##
##Example, Default file name for the MOD16 (ET) product will be MOD16A2.A2000M09.h24v07.105.2013121042253.hdf.ET_1km.tif. This will be
##renamed to A2013M11h24v07ET_1km.tif, after selecting 9th to 16th characters, 18th to 23rd characters and
##43rd to the last character and combining them. 
for f in *.tif
do
c1=`echo "$f" | cut -c9-16` 
c2=`echo "$f" | cut -c18-23` 
c3=`echo "$f" | cut -c47-56` 
c=$c1$c2$c3   
mv `echo "$f"` `echo "$c"` 
done
