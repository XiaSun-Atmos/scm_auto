# Single Column Model Automation Workflow

Last Update: Aug, 2025

If you have questions, please contact the lead developer, Xia Sun at xia.sun@colorado.edu

## Description
Rocoto workflow and job scripts to run SCM simulations over an array of columns for extended periods of time.
The scripts are developed based on the [Common Community Physics Package (CCPP) SCM](https://github.com/NCAR/ccpp-scm).
The workflow includes seven jobs, pertaining to pre-processing, SCM simulations, and post-processing:
* *combine_ic* - combine initial condition (IC) data files temporally
* *split_ic* - split 4-D IC dataset generatede from combine_ic to single columns
* *scm_py* - conduct SCM runs over all columns. 
* *concate_vars* - Concatenate the SCM variables spatially 
* *tar_scm* - tar scm files to reduce number of files

## Prerequisites
* Rocoto Workflow Management System
* Python
* GNU Parallel

## Usage

`rocotorun -d scm_auto.db -w scm_auto.xml`

More information on how to use Rocoto are available in the [Rocoto documentation](http://christopherwharrop.github.io/rocoto/).
