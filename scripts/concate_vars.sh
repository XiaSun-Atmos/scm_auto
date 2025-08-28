#!/bin/bash -l
###############################################################
## Abstract:
## Concatenate CCPP SCM outputs along lon, lat  
## CDATE  : current date (YYYYMMDDHH)
## ICON_IC : /full/path/to/ICON/IC
## COMBINE_IC : /full/path/to/combined/IC
## cyc    : current cycle (HH)
## SCRIPTS: /full/path/to/job/scripts
## PYSCRIPTS: /full/path/to/python/scripts
## CONCATE_OUTPUT: /full/path/to/concatenate/output
## author: Xia Sun, CIRES at CU Boulder/NOAA Global Systems Laboratory (Xia.Sun@colorado.edu)
###############################################################


module load ncarenv/23.10
module load conda/latest
conda init
conda activate npl

yyyy=$(echo $CDATE | cut -c1-4)
mm=$(echo $CDATE | cut -c5-6)
dd=$(echo $CDATE | cut -c7-8)
cyc=${cyc:-$(echo $CDATE | cut -c9-10)}

mkdir ${SCM_RESULTS}/${CCPP_SUITE}/${mm}_${dd}_${cyc}/output_all

	export yyyy
	export mm
	export dd
	export cyc

	cd ${SCM_RESULTS}/${CCPP_SUITE}/${mm}_${dd}_${cyc}/

if [ -f "${SCM_RESULTS}/${CCPP_SUITE}/${mm}_${dd}_${cyc}/output_all/CCPP_${CCPP_SUITE}_icon_dT_dt_pbl_2016${mm}${dd}${cyc}.nc" ]; then
		echo "Lons likely finished"

		cp -r $PYSCRIPTS/concat_vars_lat_paral.py concat_lat_${mm}_${dd}_${cyc}.py
		python concat_lat_${mm}_${dd}_${cyc}.py
		# Check the exit code ($?)
		if [ $? -eq 0 ]; then
		  echo "Python script finished with no error!"

		  find "${SCM_RESULTS}/${CCPP_SUITE}/${mm}_${dd}_${cyc}/output_all" -mindepth 1 -type d -exec rm -rf {} +

		else
		  echo "Python script failed!" >&2
		  exit 1  # Exit with error so the pipeline stops
		fi

else	
	echo "Fresh start"
	cp -r $PYSCRIPTS/concat_vars_lon_paral.py concat_lon_${mm}_${dd}_${cyc}.py
	python concat_lon_${mm}_${dd}_${cyc}.py
	sync
	sleep 10
	cp -r $PYSCRIPTS/concat_vars_lat_paral.py concat_lat_${mm}_${dd}_${cyc}.py
	python concat_lat_${mm}_${dd}_${cyc}.py
	# Check the exit code ($?)
	if [ $? -eq 0 ]; then
	  echo "Python script finished with no error!"

	  find "${SCM_RESULTS}/${CCPP_SUITE}/${mm}_${dd}_${cyc}/output_all" -mindepth 1 -type d -exec rm -rf {} +

	else
	  echo "Python script failed!" >&2
	  exit 1  # Exit with error so the pipeline stops
	fi
fi

