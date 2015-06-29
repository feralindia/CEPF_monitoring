#!/bin/bash
for TIF in *.tif; do r.in.gdal in="${TIF}" out="`echo ${TIF} | cut -d"." -f1`"  ; done
