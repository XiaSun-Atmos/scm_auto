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
###############################################################

module load intel-oneapi-compilers/2022.2.1
module load netcdf-c
module load nco
module load parallel
module load python/3.9.16
source /home/xiasun/concate39_env/bin/activate
time_inst="time_inst"
export time_inst
ulimit -u 9000

yyyy=$(echo $CDATE | cut -c1-4)
mm=$(echo $CDATE | cut -c5-6)
dd=$(echo $CDATE | cut -c7-8)
cyc=${cyc:-$(echo $CDATE | cut -c9-10)}
suite1=SCM_GFS_v17_HR3
export suite1
mkdir ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all
minsize=5000

concat_scm (){

	# Define the array
	ic_array=("T" "u" "v" "qv" "pres")

	yyyy=$(echo $CDATE | cut -c1-4)
	mm=$(echo $CDATE | cut -c5-6)
	dd=$(echo $CDATE | cut -c7-8)
	cyc=${cyc:-$(echo $CDATE | cut -c9-10)}


	yyyy3=$(echo $CDATE_3 | cut -c1-4)
	mm3=$(echo $CDATE_3 | cut -c5-6)
	dd3=$(echo $CDATE_3 | cut -c7-8)
	cyc3=${cyc6:-$(echo $CDATE_3 | cut -c9-10)}


	yyyy6=$(echo $CDATE_6 | cut -c1-4)
	mm6=$(echo $CDATE_6 | cut -c5-6)
	dd6=$(echo $CDATE_6 | cut -c7-8)
	cyc6=${cyc6:-$(echo $CDATE_6 | cut -c9-10)}

	echo ${yyyy6}-${mm6}-${dd6} ${cyc6}:00:00

	# datestamp6="${yyyy6}-${mm6}-${dd6} ${cyc6}:00:00"
	echo `date -d "${mm6}/${dd6}/${yyyy6} ${cyc6}:00" "+%s"`
	datestamp6=`echo ${mm6}/${dd6}/${yyyy6} ${cyc6}:00`
	datestamp3=`echo ${mm3}/${dd3}/${yyyy3} ${cyc3}:00`
	datestampic=`echo ${mm}/${dd}/${yyyy} ${cyc}:00`
	datestamp0="08/11/2016 00:00"

	delta6=$(($(date -d "$datestamp6" +%s)-$(date -d "$datestamp0" +%s)))
	echo $delta6
	delta3=$(($(date -d "$datestamp3" +%s)-$(date -d "$datestamp0" +%s)))
	deltaic=$(($(date -d "$datestampic" +%s)-$(date -d "$datestamp0" +%s)))

	minsize=5000
	time_inst="time_inst"
	export time_inst

	export yyyy
	export mm
	export dd
	export cyc
	echo $1 $2

	nlat=$1
	export nlat

 	# Check if the concatnated lat file exists; This saves time if some concatnated lat files already done
 	echo "${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${2}/${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat${1}_F6.nc"
	if [ -e "${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${2}/${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat${1}_F6.nc" ]; then
	  echo "Concatnated Lat File exists. Exiting the script."
	  exit 0
	else
	  echo "Concatnated Lat File does not exist. Continuing the script."

		cd ${SCM_RESULTS}/${mm}_${dd}_${cyc}/lat_$1
		
		cp -r $PYSCRIPTS/concat_lon_inst_2d_3d.py concat_lon_$2.py
		var=$2
		export var
		python concat_lon_$2.py

		actsize3=`wc -c <"${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc"`  # check if python work properly
		echo $actsize3

		actsize6=`wc -c <"${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc"`  # check if python work properly

		if [[ "$actsize3" -lt $minsize ]] || [[ "$actsize6" -lt $minsize ]] ; then
			python concat_lon_$2.py
		fi

		actsize3=`wc -c <"${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc"`  # check if python work properly
		echo $actsize3

		actsize6=`wc -c <"${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc"`  # check if python work properly

		if [[ "$actsize3" -lt $minsize ]] || [[ "$actsize6" -lt $minsize ]] ; then
			python concat_lon_$2.py
		fi
		actsize3=`wc -c <"${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc"`  # check if python work properly
		echo $actsize3

		actsize6=`wc -c <"${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc"`  # check if python work properly

		if [[ "$actsize3" -lt $minsize ]] || [[ "$actsize6" -lt $minsize ]] ; then
			python concat_lon_$2.py
		fi


		module load nco
		echo ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc
		# process F3
		ncrename -h  -v time_inst,time ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc -O ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc # rename time_inst var to time
		ncatted -h -O -a units,time,o,c,"seconds since 2016-08-11 00:00:00" \
		-a long_name,time,a,c,"time" \
		-a calendar,time,a,c,"proleptic_gregorian" \
		${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc  # change the time unit
		ncap2 -h -s "time(:)={${delta3}}" ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc -O ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc  #change time value from 2016-08-11 00:00:00

		# process F6	
		ncrename -h  -v time_inst,time ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc -O ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc # rename time_inst var to time
		ncatted -h -O -a units,time,o,c,"seconds since 2016-08-11 00:00:00" \
		-a long_name,time,a,c,"time" \
		-a calendar,time,a,c,"proleptic_gregorian" \
		${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc  # change the time unit
		ncap2 -h -s "time(:)={${delta6}}" ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc -O ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc  #change time value from 2016-08-11 00:00:00

		mkdir ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${var}

		mv ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${var}/
		mv ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${var}/
		# Iterate over the IC vars to export IC vars on SCM levs, per Edward's request
		for icvars in "${ic_array[@]}"; do
		    # Check if the variable is equal to the current array element
		    if [ "$var" = "$icvars" ]; then
				ncrename -h  -v time_inst,time ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F0.nc -O ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F0.nc # rename time_inst var to time
				ncatted -h -O -a units,time,o,c,"seconds since 2016-08-11 00:00:00" \
				-a long_name,time,a,c,"time" \
				-a calendar,time,a,c,"proleptic_gregorian" \
				${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F0.nc  # change the time unit
				ncap2 -h -s "time(:)={${deltaic}}" ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F0.nc -O ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F0.nc  #change time value from 2016-08-11 00:00:00
				mv ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F0.nc ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${var}/
		        break
		    fi
		done
	fi

}
export -f concat_scm

echo ${SCRIPTS}
parallel -u -j 40 concat_scm ::: {0..199} ::: $(<${SCRIPTS}/vars_inst.txt)

ic_array=("T" "u" "v" "qv" "pres")
for var in $(<${SCRIPTS}/vars_inst.txt)
do
	yyyy=$(echo $CDATE | cut -c1-4)
	mm=$(echo $CDATE | cut -c5-6)
	dd=$(echo $CDATE | cut -c7-8)
	cyc=${cyc:-$(echo $CDATE | cut -c9-10)}

	export var
	export yyyy
	export mm
	export dd
	export cyc

	cd ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${var}/
	output_all='${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${var}'
	export output_all

	cp -r ${PYSCRIPTS}/concat_lat_2d_3d.py concat_lat_${var}.py
	
	python concat_lat_${var}.py #concate from all lats
	dlat3=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F3.nc" | awk '/dimensions:/,/variables:/' | grep 'lat =' | awk '{print $3}' | tr -d ';')
	dlon3=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F3.nc" | awk '/dimensions:/,/variables:/' | grep 'lon =' | awk '{print $3}' | tr -d ';')

	dlat6=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F6.nc" | awk '/dimensions:/,/variables:/' | grep 'lat =' | awk '{print $3}' | tr -d ';')
	dlon6=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F6.nc" | awk '/dimensions:/,/variables:/' | grep 'lon =' | awk '{print $3}' | tr -d ';')
	echo "$dlat3 $dlon3 $dlat6 $dlon6"

	# Check dimension length
	if [[ $dlat3 -ne 200 ]] || [[ $dlon3 -ne 220 ]] || [[ $dlat6 -ne 200 ]] || [[ $dlon6 -ne 220 ]] ; then
	    echo "Not all dimensions are correct."
		python concat_lat_${var}.py #concate from all lats'
		dlat3=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F3.nc" | awk '/dimensions:/,/variables:/' | grep 'lat =' | awk '{print $3}' | tr -d ';')
		dlon3=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F3.nc" | awk '/dimensions:/,/variables:/' | grep 'lon =' | awk '{print $3}' | tr -d ';')

		dlat6=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F6.nc" | awk '/dimensions:/,/variables:/' | grep 'lat =' | awk '{print $3}' | tr -d ';')
		dlon6=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F6.nc" | awk '/dimensions:/,/variables:/' | grep 'lon =' | awk '{print $3}' | tr -d ';')
		echo "$dlat3 $dlon3 $dlat6 $dlon6"
	else
		echo "All dimensions are correct."
	fi

	# Check dimension length
	if [[ $dlat3 -ne 200 ]] || [[ $dlon3 -ne 220 ]] || [[ $dlat6 -ne 200 ]] || [[ $dlon6 -ne 220 ]] ; then
	    echo "Not all dimensions are correct."
		python concat_lat_${var}.py #concate from all lats
		dlat3=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F3.nc" | awk '/dimensions:/,/variables:/' | grep 'lat =' | awk '{print $3}' | tr -d ';')
		dlon3=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F3.nc" | awk '/dimensions:/,/variables:/' | grep 'lon =' | awk '{print $3}' | tr -d ';')

		dlat6=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F6.nc" | awk '/dimensions:/,/variables:/' | grep 'lat =' | awk '{print $3}' | tr -d ';')
		dlon6=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F6.nc" | awk '/dimensions:/,/variables:/' | grep 'lon =' | awk '{print $3}' | tr -d ';')
		echo "$dlat3 $dlon3 $dlat6 $dlon6"

	else
		echo "All dimensions are correct."
		# remove intermediate concatnated lat files
	fi

	# Check dimension length
	if [[ $dlat3 -ne 200 ]] || [[ $dlon3 -ne 220 ]] || [[ $dlat6 -ne 200 ]] || [[ $dlon6 -ne 220 ]] ; then
	    echo "Not all dimensions are correct."
		python concat_lat_${var}.py #concate from all lats
	else
		echo "All dimensions are correct."
		# remove intermediate concatnated lat files
		rm -rf ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${var}/${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_lat*_F3.nc
		rm -rf ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${var}/${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_lat*_F6.nc
		rm -rf ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${var}/${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_lat*_F0.nc
	fi   
done
