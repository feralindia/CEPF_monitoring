# CEPF_monitoring

## Introduction

This repository provides details of the programming code used for the analysis of landcover change across the Western Ghats of India between the period 2000 and 2013. 

## How to use this repository

Most of the script have extensive comments and explanations. Relevant references and notes on procedures used are provided for some routines which are not self evident. Additionally the repository provides markdown files for most of the scripts along with references to the modules and libraries used. This file has the same name as the script except that it ends with the suffix *.md. The markdown file addtinoally contains:
    
    *      Citations of relevant papers and packages.
    *      Explanations of algorithms and analysis. Each section of this document is named after the R scripts used. 

Please note that we have used other software in conjunction with R, including but not only GRASS, GDAL and Quantum GIS. Also note, all the processing was done on Linux and the script may not work as expected on other operating systems. In some cases, a single “chunk” of code or script file has been broken down into sub-units for the sake of explanation.

## ToDo

Please consider this script as work in progress. We're trying to clean up the code and re-orgnise it for consistency and to remove redundancies. Also, we're trying to multi-core some of the code to speed up the analysis.
