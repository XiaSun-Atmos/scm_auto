#!/bin/bash -l
###############################################################
## Abstract:
## Concatenate CCPP SCM outputs along time for 40-day simulation 
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

	mkdir ${CONCATE_OUTPUT}/concate_v2.0_${CCPP_SUITE}/2016_ICON_${CCPP_SUITE}
	mkdir ${CONCATE_OUTPUT}/concate_v2.0_${CCPP_SUITE}/2016_ICON_${CCPP_SUITE}/$1
	cd ${CONCATE_OUTPUT}/concate_v2.0_${CCPP_SUITE}/2016_ICON_${CCPP_SUITE}/$1
	var=$1
	export var
        rm -r *.nc
        rm -r *.tmp
	cp -r ${CONCATE_OUTPUT}/concate_v2.0_${CCPP_SUITE}/*/output_all/${var}/CCPP_${CCPP_SUITE}_ICON*.nc .
        time_dummy=`ncdump -h CCPP_${CCPP_SUITE}_ICON_${var}_2016081103.nc |sed '5 !d'`
        time_str=`echo "${time_dummy%=*}" |xargs` #carve out time dimension name
        for f in CCPP_${CCPP_SUITE}_ICON_${1}*.nc; do
             echo ${f}
             ncks -h -O --mk_rec_dmn ${time_str} ${f} ${f}  #assign record dimension
        done
        ncrcat -h CCPP_${CCPP_SUITE}_ICON_${1}*.nc 2016_ICON_CCPP_${CCPP_SUITE}_${1}.nc #concatnate along record dimension using NCO
}
export -f concat_scm

parallel concat_scm ::: $(</home/xiasun/work2_xiasun/workflow/scripts/vars_accum.txt)
