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
export PATH="/home/xiasun/xiasun/anaconda3/bin:$PATH"
module load nco
# var="u"
time_inst="time_inst"
export time_inst
# export var
minsize=18000
concat_scm (){
	yyyy=$(echo $CDATE | cut -c1-4)
	mm=$(echo $CDATE | cut -c5-6)
	dd=$(echo $CDATE | cut -c7-8)
	cyc=${cyc:-$(echo $CDATE | cut -c9-10)}

	yyyy6=$(echo $CDATE_6 | cut -c1-4)
	mm6=$(echo $CDATE_6 | cut -c5-6)
	dd6=$(echo $CDATE_6 | cut -c7-8)
	cyc6=${cyc6:-$(echo $CDATE_6 | cut -c9-10)}

	echo ${yyyy6}-${mm6}-${dd6} ${cyc6}:00:00

	# datestamp6="${yyyy6}-${mm6}-${dd6} ${cyc6}:00:00"
	echo `date -d "${mm6}/${dd6}/${yyyy6} ${cyc6}:00" "+%s"`
	datestamp6=`echo ${mm6}/${dd6}/${yyyy6} ${cyc6}:00`
	echo $datestamp6
	datestamp0="08/11/2016 00:00"
	delta=$(($(date -d "$datestamp6" +%s)-$(date -d "$datestamp0" +%s)))
	echo $delta

	export yyyy
	export mm
	export dd
	export cyc
	echo $1 $2
	echo $1
	echo $2
	mkdir ${CONCATE_OUTPUT}/concate_v2.0_${CCPP_SUITE}/${mm}_${dd}_${cyc}
	mkdir ${CONCATE_OUTPUT}/concate_v2.0_${CCPP_SUITE}/${mm}_${dd}_${cyc}/${mm}_${dd}_${cyc}_output_lat$1
	cd ${CONCATE_OUTPUT}/concate_v2.0_${CCPP_SUITE}/${mm}_${dd}_${cyc}/${mm}_${dd}_${cyc}_output_lat$1
	# rm -r output*.nc
	for ilon in  {0..219}; do
		rm -r ${CONCATE_OUTPUT}/concate_v2.0_${CCPP_SUITE}/${mm}_${dd}_${cyc}/${mm}_${dd}_${cyc}_output_lat$1/mumip_scm_${yyyy}$mm$dd.${cyc}_lat${1}_lon${ilon}_v2.0_${CCPP_SUITE}.nc
		ln -s ${SCM_RESULTS}/v2.0_${CCPP_SUITE}/${mm}_${dd}_${cyc}/mumip_scm_${yyyy}$mm$dd.${cyc}_lat$1_lon${ilon}_v2.0_${CCPP_SUITE}.nc ${CONCATE_OUTPUT}/concate_v2.0_${CCPP_SUITE}/${mm}_${dd}_${cyc}/${mm}_${dd}_${cyc}_output_lat$1/
	done
	cp -r $PYSCRIPTS/concat_lon_inst.py concat_lon_$2.py
	var=$2
	export var
	python concat_lon_$2.py
	actsize=`wc -c <"${CCPP_SUITE}_ICON_$2_$yyyy$mm$dd$cyc.nc"`  # check if python work properly
	echo $actsize
	if (( $actsize -lt $minsize )); then
		python concat_lon_$2.py
	fi
	if (( $actsize -lt $minsize )); then
		python concat_lon_$2.py
	fi
	if (( $actsize -lt $minsize )); then
		python concat_lon_$2.py
	fi
	module load nco
	ncrename -h  -v time_inst,time ${CCPP_SUITE}_ICON_${2}_$yyyy$mm$dd$cyc.nc -O ${CCPP_SUITE}_ICON_${2}_$yyyy$mm$dd$cyc.nc # rename time_inst var to time
	ncatted -h -O -a units,time,o,c,"seconds since 2016-08-11 00:00:00" ${CCPP_SUITE}_ICON_${2}_$yyyy$mm$dd$cyc.nc # change the time unit
	ncatted -h -O -a long_name,time,a,c,"time" ${CCPP_SUITE}_ICON_${2}_$yyyy$mm$dd$cyc.nc
	ncatted -h -O -a calendar,time,a,c,"proleptic_gregorian" ${CCPP_SUITE}_ICON_${2}_$yyyy$mm$dd$cyc.nc
	ncap2 -h -s "time(:)={${delta}}" ${CCPP_SUITE}_ICON_${2}_$yyyy$mm$dd$cyc.nc -O ${CCPP_SUITE}_ICON_${2}_$yyyy$mm$dd$cyc.nc   #change time value from 2016-08-11 00:00:00
	mv ${CCPP_SUITE}_ICON_${2}_$yyyy$mm$dd$cyc.nc ${CCPP_SUITE}_ICON_${2}_$yyyy$mm$dd${cyc}_lat$1.nc
}
export -f concat_scm

parallel concat_scm ::: {0..199} ::: $(</home/xiasun/work2_xiasun/workflow_v1/scripts/vars_inst.txt)

for var in $(</home/xiasun/work2_xiasun/workflow_v1/scripts/vars_inst.txt)
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

	mkdir ${CONCATE_OUTPUT}/concate_v2.0_${CCPP_SUITE}/${mm}_${dd}_${cyc}/output_all
	cd ${CONCATE_OUTPUT}/concate_v2.0_${CCPP_SUITE}/${mm}_${dd}_${cyc}/output_all
	mkdir ${var}
	cd ${var}
        rm -r ${CCPP_SUITE}_ICON*
	ln -s ${CONCATE_OUTPUT}/concate_v2.0_${CCPP_SUITE}/${mm}_${dd}_${cyc}/${mm}_${dd}_${cyc}_output_lat*/${CCPP_SUITE}_ICON_${var}_*.nc .
	cp -r ${PYSCRIPTS}/concat_lat.py concat_lat_${var}.py
	python concat_lat_${var}.py #concate from all lats
done


