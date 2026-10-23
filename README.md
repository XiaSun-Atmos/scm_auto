# Single Column Model Automation Workflow

## Description
Rocoto workflow and job scripts to run SCM simulations over an array of columns for extended periods of time.
The scripts are developed based on the [Common Community Physics Package (CCPP) SCM](https://github.com/NCAR/ccpp-scm).
The workflow includes seven jobs, pertaining to pre-processing, SCM simulations, and post-processing:
* *combine_ic* - combine initial condition (IC) data files temporally,convert to DEPHY format, and add post-calculated vertical advection
* *split_ic* - split 4-D IC dataset generatede from combine_ic to single columns
* *scm_py* - conduct SCM runs over all columns. 
* *concate_vars* - concatenate the SCM variables spatially 
* *tar_scm* - tar scm files to reduce number of files
* *concate_time* - concatenate all cycles into per-variable files

## Prerequisites
* Rocoto Workflow Management System
* Python
* GNU Parallel

## Usage
1. Set up the `/PATH/TO/...` entities in `scm_auto.xml`, and Python and library paths in the job scripts
2. Set `STDATE`,`EDATE`,`CCPP_SUITE`,`EXP`, and `GRID` for your experiment. 
3. Run `rocotorun -d scm_auto.db -w scm_auto.xml`

More information on how to use Rocoto are available in the [Rocoto documentation](http://christopherwharrop.github.io/rocoto/).

If you have questions using this SCM automation workflow, please get in touch with the lead developer, X. Sun at xia.sun@colorado.edu
Other contributors include: K. Newman, W. Mayfield, J. Simpson
