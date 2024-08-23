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

export PATH="/work/noaa/gmtb/xiasun/MU-MIP/tools/gnu_parallel/bin:$PATH"
#module load python/3.7.5
#source /work2/noaa/gmtb/xiasun/env_37/bin/activate
module load nco
module load intelpython3/2022.1.2
source ~/intelpy_env/bin/activate
# var="u"
time_inst="time_diag"
export time_inst
# export var
minsize=50000

concat_scm (){
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

	minsize=50000

	echo ${yyyy6}-${mm6}-${dd6} ${cyc6}:00:00

	datestamp6=`echo ${mm6}/${dd6}/${yyyy6} ${cyc6}:00`
	datestamp3=`echo ${mm3}/${dd3}/${yyyy3} ${cyc3}:00`
	echo $datestamp6
	datestamp0="08/11/2016 00:00"
	delta6=$(($(date -d "$datestamp6" +%s)-$(date -d "$datestamp0" +%s)))
	echo $delta6
	delta3=$(($(date -d "$datestamp3" +%s)-$(date -d "$datestamp0" +%s)))
	time_inst="time_diag"
	export time_inst


	export yyyy
	export mm
	export dd
	export cyc
	echo $1 $2

	nlat=$1
	export nlat
	# Check if the concatnated lat file exists; This saves time if some concatnated lat files already done
	if [ -e "${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${2}/${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat${1}_F6.nc" ]; then
	  echo "Concatnated Lat File exists. Exiting the script."
	  exit 0
	else
	  echo "Concatnated Lat File does not exist. Continuing the script."
			cd ${SCM_RESULTS}/${mm}_${dd}_${cyc}/lat_$1
			# rm -r output*.nc
			cp -r $PYSCRIPTS/concat_lon_accum_2d_3d.py concat_lon_$2.py
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
			# process F3
			ncrename -h  -v time_diag,time ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc -O ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc # rename time_inst var to time
			ncatted -h -O -a units,time,o,c,"seconds since 2016-08-11 00:00:00" \
			-a long_name,time,a,c,"time" \
			-a calendar,time,a,c,"proleptic_gregorian" \
			${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc # change the time unit

			ncap2 -h -s "time(:)={${delta3}}" ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc -O ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc   #change time value from 2016-08-11 00:00:00
			
			# process F6
			ncrename -h  -v time_diag,time ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc -O ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc # rename time_inst var to time
			ncatted -h -O -a units,time,o,c,"seconds since 2016-08-11 00:00:00" \
			-a long_name,time,a,c,"time" \
			-a calendar,time,a,c,"proleptic_gregorian" \
			${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc # change the time unit

			ncap2 -h -s "time(:)={${delta6}}" ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc -O ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc   #change time value from 2016-08-11 00:00:00
			


			mkdir ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${var}
			mv ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F3.nc ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${var}/
			mv ${CCPP_SUITE}_${EXP}_${2}_$yyyy$mm$dd${cyc}_lat$1_F6.nc ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/${var}/
		fi
}
export -f concat_scm

parallel -u -j 36 concat_scm ::: {0..199} ::: $(<${SCRIPTS}/vars_accum_2.txt)

for var in $(<${SCRIPTS}/vars_accum_2.txt)
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
	cp -r ${PYSCRIPTS}/concat_lat_2d_3d.py concat_lat_${var}.py
	python concat_lat_${var}.py #concate from all lats
	# check if python worked properly

	dlat3=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F3.nc" | awk '/dimensions:/,/variables:/' | grep 'lat =' | awk '{print $3}' | tr -d ';')
	dlon3=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F3.nc" | awk '/dimensions:/,/variables:/' | grep 'lon =' | awk '{print $3}' | tr -d ';')

	dlat6=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F6.nc" | awk '/dimensions:/,/variables:/' | grep 'lat =' | awk '{print $3}' | tr -d ';')
	dlon6=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F6.nc" | awk '/dimensions:/,/variables:/' | grep 'lon =' | awk '{print $3}' | tr -d ';')




	# Check dimension length
	if [[ $dlat3 -ne 200 ]] || [[ $dlon3 -ne 220 ]] || [[ $dlat6 -ne 200 ]] || [[ $dlon6 -ne 220 ]] ; then
	    echo "Not all dimensions are correct."
		python concat_lat_${var}.py #concate from all lats
		dlat3=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F3.nc" | awk '/dimensions:/,/variables:/' | grep 'lat =' | awk '{print $3}' | tr -d ';')
		dlon3=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F3.nc" | awk '/dimensions:/,/variables:/' | grep 'lon =' | awk '{print $3}' | tr -d ';')

		dlat6=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F6.nc" | awk '/dimensions:/,/variables:/' | grep 'lat =' | awk '{print $3}' | tr -d ';')
		dlon6=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F6.nc" | awk '/dimensions:/,/variables:/' | grep 'lon =' | awk '{print $3}' | tr -d ';')

	else
		echo "All dimensions are correct."
		# remove intermediate concatnated lat files
	fi


	# Check dimension length
	if [[ $dlat3 -ne 200 ]] || [[ $dlon3 -ne 220 ]] || [[ $dlat6 -ne 200 ]] || [[ $dlon6 -ne 220 ]] ; then
	    echo "Not all dimensions are correct."
		python concat_lat_${var}.py #concate from all lats
		dlat3=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F3.nc" | awk '/dimensions:/,/variables:/' | grep 'lat =' | awk '{print $3}' | tr -d ';')
		dlon3=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F3.nc" | awk '/dimensions:/,/variables:/' | grep 'lon =' | awk '{print $3}' | tr -d ';')

		dlat6=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F6.nc" | awk '/dimensions:/,/variables:/' | grep 'lat =' | awk '{print $3}' | tr -d ';')
		dlon6=$(ncdump -h "CCPP_${CCPP_SUITE}_${EXP}_${var}_$yyyy$mm$dd${cyc}_F6.nc" | awk '/dimensions:/,/variables:/' | grep 'lon =' | awk '{print $3}' | tr -d ';')

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
	fi
done



