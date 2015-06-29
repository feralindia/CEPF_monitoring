#!/bin/bash
MODFILES=$(g.mlist -p type=rast pattern=*Quality mapset=land_class)
for FILES in $MODFILES; do r.reclass --overwrite input="${FILES}" output="Q${FILES}" rules="/media/HP v210w/mod13q1viqa_reclassfile" ; done
