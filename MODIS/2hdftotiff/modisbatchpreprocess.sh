#!/bin/bash
# Modify the line above to the location of your BASH interpreter.
#
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
exit 0
