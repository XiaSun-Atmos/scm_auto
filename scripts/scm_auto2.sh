#!/bin/bash -x
###############################################################
## Abstract:
## 1.Split ICON IC to each grid points and convert to DEPHY format
## 2. Run scm at each grid point in parallel
## 3. Add lat and lon dimension to CCPP SCM output and move to &
## another directory for future concatenate
## CDATE  : current date (YYYYMMDDHH)
## ICON_IC : /full/path/to/ICON/IC
## COMBINE_IC : /full/path/to/combined/IC
## cyc    : current cycle (HH)
## SCRIPTS: /full/path/to/job/scripts
###############################################################

ulimit -u 9000

module purge
module use /work2/noaa/gmtb/mumip/scm_build/ccpp-scm-v7/ccpp-scm/scm/etc/modules
module load orion_intel
module load nco
module load parallel
yyyy=$(echo $CDATE | cut -c1-4)
mm=$(echo $CDATE | cut -c5-6)
dd=$(echo $CDATE | cut -c7-8)
cyc=${cyc:-$(echo $CDATE | cut -c9-10)}

yyyy3=$(echo $CDATE_3 | cut -c1-4)
mm3=$(echo $CDATE_3 | cut -c5-6)
dd3=$(echo $CDATE_3 | cut -c7-8)
cyc3=$(echo $CDATE_3 | cut -c9-10)

yyyy6=$(echo $CDATE_6 | cut -c1-4)
mm6=$(echo $CDATE_6 | cut -c5-6)
dd6=$(echo $CDATE_6 | cut -c7-8)
cyc6=$(echo $CDATE_6 | cut -c9-10)

yyyy9=$(echo $CDATE_9 | cut -c1-4)
mm9=$(echo $CDATE_9 | cut -c5-6)
dd9=$(echo $CDATE_9 | cut -c7-8)
cyc9=$(echo $CDATE_9 | cut -c9-10)

# make dirs for scm outputs
mkdir ${SCM_RESULTS}/
mkdir ${SCM_RESULTS}/${mm}_${dd}_${cyc}

minsize=50000
scm_auto_batch (){
	minsize=50000
	yyyy=$(echo $CDATE | cut -c1-4)
	mm=$(echo $CDATE | cut -c5-6)
	dd=$(echo $CDATE | cut -c7-8)
	cyc=${cyc:-$(echo $CDATE | cut -c9-10)}
	cyc9=$(echo $CDATE_9 | cut -c9-10)
	yyyy9=$(echo $CDATE_9 | cut -c1-4)
	mm9=$(echo $CDATE_9 | cut -c5-6)
	dd9=$(echo $CDATE_9 | cut -c7-8)
	cyc9=$(echo $CDATE_9 | cut -c9-10)

	if [ -e "${SCM_RESULTS}/${mm}_${dd}_${cyc}/lat_$1/mumip_${EXP}_scm_${yyyy}$mm$dd.${cyc}_lat$1_lon$2_${CCPP_SUITE}.nc" ]; then
	  echo "SCM File exists. Exiting the script."
	  date
	  exit 0
	else
	  echo "File does not exist. Continuing the script."

		############# Run SCM at lat and lon ##############
		cd ${SCM_ROOT}/scm/etc/case_config
		cp -r ${SCRIPTS}/${EXP}_cor_F0_template.nml ${EXP}_lat$1_lon$2_$mm$dd$cyc.nml
		sed -i "s/CASENAME/${EXP}_lat$1_lon$2_$mm$dd$cyc/g" ${EXP}_lat$1_lon$2_$mm$dd$cyc.nml
		cd ${SCM_ROOT}/scm/data/processed_case_input
		rm -rf ${EXP}_lat${1}_lon${2}_${mm}${dd}${cyc}_SCM_driver.nc
		ln -s ${SPLIT_IC}/${mm}_${dd}_${cyc}/lat_$1/mumip_${EXP}_${GRID}_IO_0.2_${yyyy}$mm$dd.${cyc}_combined_lat$1_lon$2.nc ${EXP}_lat$1_lon$2_${mm}${dd}${cyc}_SCM_driver.nc
		cd ${SCM_ROOT}/scm/

		rm -rf src_lat$1_lon$2_$mm$dd${cyc}
		mkdir lat_$1
		cd lat_$1 
		mkdir src_lat$1_lon$2_$mm$dd${cyc} 
		cd src_lat$1_lon$2_$mm$dd${cyc}
		ln -s ${SCM_ROOT}/scm/src/* .

		pwd
		./run_scm.py -c ${EXP}_lat$1_lon$2_$mm$dd$cyc -s ${CCPP_SUITE} --n_itt_diag 1 --n_itt_out 1 --run_dir ../run_lat$1_lon$2_$mm$dd$cyc
		scm_actsize=`wc -c <"${SCM_ROOT}/scm/lat_$1/run_lat$1_lon$2_$mm$dd$cyc/output_${EXP}_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}/output.nc"`  # check if scm work properly
		echo ${scm_actsize}

		# if size of SCM output file is less than the specified minimum size, rerun the SCM (sometimes this will resolve whatever issue the run had)
		if [[ ${scm_actsize} -lt $minsize ]]; then
			echo "reruning scm for $1 $2"
			./run_scm.py -c ${EXP}_lat$1_lon$2_$mm$dd$cyc -s ${CCPP_SUITE} --n_itt_diag 1 --n_itt_out 1 --run_dir ../run_lat$1_lon$2_$mm$dd$cyc
			scm_actsize=`wc -c <"${SCM_ROOT}/scm/lat_$1/run_lat$1_lon$2_$mm$dd$cyc/output_${EXP}_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}/output.nc"`  # check if scm work properly
		else
			echo "scm for $1 $2 okay"
		fi

		if [[ ${scm_actsize} -lt $minsize ]]; then
			echo "reruning scm for $1 $2"
			./run_scm.py -c ${EXP}_lat$1_lon$2_$mm$dd$cyc -s ${CCPP_SUITE} --n_itt_diag 1 --n_itt_out 1 --run_dir ../run_lat$1_lon$2_$mm$dd$cyc
			scm_actsize=`wc -c <"${SCM_ROOT}/scm/lat_$1/run_lat$1_lon$2_$mm$dd$cyc/output_${EXP}_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}/output.nc"`  # check if scm work properly
		else
			echo "scm for $1 $2 okay"
		fi
		
		if [[ ${scm_actsize} -lt $minsize ]]; then
			echo "reruning scm for $1 $2"
			./run_scm.py -c ${EXP}_lat$1_lon$2_$mm$dd$cyc -s ${CCPP_SUITE} --n_itt_diag 1 --n_itt_out 1 --run_dir ../run_lat$1_lon$2_$mm$dd$cyc
			scm_actsize=`wc -c <"${SCM_ROOT}/scm/lat_$1/run_lat$1_lon$2_$mm$dd$cyc/output_${EXP}_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}/output.nc"`  # check if scm work properly
		else
			echo "scm for $1 $2 okay"
		fi

		############# Add lat and lon dimension to SCM output and move to another dir for concatenation ##############
		cd ${RUN_DIR}/lat_$1/run_lat$1_lon$2_$mm$dd$cyc/output_${EXP}_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}
		rm -r output_latlon.nc
		rm -r *.tmp
		pwd

	    lat_val=`ncdump -v lat ${SPLIT_IC}/${mm}_${dd}_${cyc}/lat_$1/mumip_${EXP}_${GRID}_IO_0.2_${yyyy}$mm$dd.${cyc}_combined_lat$1_lon$2.nc | tail -n 2 | head -n 1 | sed -e 's/lat = \(.*\) ;/\1/' |sed 's/ //g'`
		echo "$lat_val"
	    lon_val=`ncdump -v lon ${SPLIT_IC}/${mm}_${dd}_${cyc}/lat_$1/mumip_${EXP}_${GRID}_IO_0.2_${yyyy}$mm$dd.${cyc}_combined_lat$1_lon$2.nc | tail -n 2 | head -n 1 | sed -e 's/lon = \(.*\) ;/\1/' |sed 's/ //g'`
		echo "${lon_val}"
		ncap2 -h -s 'defdim("lat",1);lat[lat]='${lat_val}';lat@long_name="latitude";lat@standard_name="latitude";lat@units="degrees_north"' output.nc -O output_latlon.nc
		ncap2 -h -s 'defdim("lon",1);lon[lon]='${lon_val}';lon@long_name="longitude";lon@standard_name="longitude";lon@units="degrees_east"' output_latlon.nc -O output_latlon.nc
		while read line; do
		 ncap2 -h -s "$line" output_latlon.nc -O output_latlon.nc
		done < $SCRIPTS/for_ncap2_127.txt
		ncwa -a hor_dim_layer output_latlon.nc -O output_latlon.nc #remove hor_dim_layer

		mkdir ${SCM_RESULTS}/${mm}_${dd}_${cyc}/lat_$1		
		mv ${RUN_DIR}/lat_$1/run_lat$1_lon$2_$mm$dd$cyc/output_${EXP}_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}/output_latlon.nc ${SCM_RESULTS}/${mm}_${dd}_${cyc}/lat_$1/mumip_${EXP}_scm_${yyyy}$mm$dd.${cyc}_lat$1_lon$2_${CCPP_SUITE}.nc 

		if [ -e "${RUN_DIR}/lat_$1/run_lat$1_lon$2_$mm$dd$cyc/output_${EXP}_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}/output_latlon.nc" ]; then
	    	echo "lat$1 lon$2 Fail"
	    	mv ${RUN_DIR}/lat_$1/run_lat$1_lon$2_$mm$dd$cyc/output_${EXP}_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}/output_latlon.nc ${SCM_RESULTS}/${mm}_${dd}_${cyc}/lat_$1/mumip_${EXP}_scm_${yyyy}$mm$dd.${cyc}_lat$1_lon$2_${CCPP_SUITE}.nc 
		else
			echo "lat$1 lon$2 Success"
			######## Clean up -- delete scm run dir ########
			rm -rf ${SCM_ROOT}/scm/lat_$1/src_lat$1_lon$2_$mm$dd${cyc}
			rm -rf ${SCM_ROOT}/scm/lat_$1/run_lat$1_lon$2_$mm$dd${cyc}
			rm -rf ${SCM_ROOT}/scm/etc/case_config/${EXP}_lat$1_lon$2_$mm$dd${cyc}.nml
			rm -rf ${SCM_ROOT}/scm/data/processed_case_input/${EXP}_lat$1_lon$2_${mm}${dd}${cyc}_SCM_driver.nc
			exit 0
		fi
	fi

}
export -f scm_auto_batch
parallel -u scm_auto_batch ::: {101..199} ::: {0..219}
