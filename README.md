# Single Column Model Automation Workflow

Last Update: Aug, 2024

## Description
Rocoto workflow and job scripts to run SCM simulations over an array of columns for extended periods of time.
The scripts are developed based on the [Common Community Physics Package (CCPP) SCM](https://github.com/NCAR/ccpp-scm).
The workflow includes seven jobs, pertaining to pre-processing, SCM simulations, and post-processing:
* *combine_ic* - combine initial condition (IC) data files temporally
* *split_ic* - split 4-D IC dataset generatede from combine_ic to single columns
* *run_scm* - conduct SCM runs over all columns. 
* *latlon_move* - Add `latitude` and `longitude` dimensions to the `output.nc` generated from CCPP SCM and them to a separate Results directory
* *concate_inst* - Concatenate the SCM instantanous variables spatially 
* *concate_accum* - Concatenate the SCM accumulative variables spatially 
* *concate_time* - Concatenate all SCM results temporarily

## Prerequisites
* Rocoto Workflow Management System
* Python
* GNU Parallel

## Usage

`rocotorun -d scm_auto.db -w scm_auto.xml`

More information on how to use Rocoto are available in the [Rocoto documentation](http://christopherwharrop.github.io/rocoto/).

Contributors: 
Xia Sun, xia.sun@noaa.gov
Kathryn Newman, knewman@ucar.edu
Will Mayfield, wmayfield@ucar.edu 