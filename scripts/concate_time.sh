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
export PATH="/work2/noaa/gmtb/xiasun/tools/gnu_parallel/bin:$PATH"
export PATH="/work2/noaa/gmtb/xiasun/anaconda3/bin:$PATH"
module load nco
ulimit -u 9000
minsize=18000
concat_scm (){
	sdate=$(echo $SDATE | cut -c1-10)
	edate=$(echo $EDATE | cut -c1-10)

	function ncdmnsz { ncks --trd -m -M ${2} | grep -E -i ": ${1}, size =" | cut -f 7 -d ' ' | uniq ; }

	ic_array=("T" "u" "v" "qv" "pres")

	mkdir -p ${CONCATE_OUTPUT}/$1
	cd ${CONCATE_OUTPUT}/$1
	var=$1
	export var
        rm -r *.nc
        rm -r *.tmp

        cp -r ${SCM_RESULTS}/*/output_all/${var}/CCPP_${CCPP_SUITE}_${EXP}_${var}_*_F3.nc .

        time_dummy=`ncdump -h CCPP_${CCPP_SUITE}_${EXP}_${var}_${sdate}_F3.nc |sed '5 !d'`
        time_str=`echo "${time_dummy%=*}" |xargs` #carve out time dimension name
	echo "${time_dummy}"
	echo "${time_str}"
        for f in CCPP_${CCPP_SUITE}_${EXP}_${1}_*_F3.nc; do
             echo ${f}
	     ncdmnsz lat ${f}
	     ncdmnsz lon ${f}
             ncks -O -h --mk_rec_dmn ${time_str} ${f} ${f}  #assign record dimension
        done
        ncrcat -O -h CCPP_${CCPP_SUITE}_${EXP}_${var}_*_F3.nc  2016_${EXP}_CCPP_${CCPP_SUITE}_${1}_${sdate}_${edate}_F3.nc #concatnate along record dimension using NCO

       cp -r ${SCM_RESULTS}/*/output_all/${var}/CCPP_${CCPP_SUITE}_${EXP}_${var}_*_F6.nc .

        for f in CCPP_${CCPP_SUITE}_${EXP}_${1}_*_F6.nc; do
             echo ${f}
             ncks -h -O --mk_rec_dmn ${time_str} ${f} ${f}  #assign record dimension
        done
        ncrcat -O -h CCPP_${CCPP_SUITE}_${EXP}_${var}_*_F6.nc  2016_${EXP}_CCPP_${CCPP_SUITE}_${1}_${sdate}_${edate}_F6.nc #concatnate along record dimension using NCO

	for icvars in "${ic_array[@]}"; do
	    # Check if the variable is equal to the current array element
	    if [ "$var" = "$icvars" ]; then
	       cp -r ${SCM_RESULTS}/*/output_all/${var}/CCPP_${CCPP_SUITE}_${EXP}_${var}_*_F0.nc .

	        for f in CCPP_${CCPP_SUITE}_${EXP}_${1}_*_F0.nc; do
	             echo ${f}
	             ncks -h -O --mk_rec_dmn ${time_str} ${f} ${f}  #assign record dimension
	        done
	        ncrcat -O -h CCPP_${CCPP_SUITE}_${EXP}_${var}_*_F0.nc  2016_${EXP}_CCPP_${CCPP_SUITE}_${1}_${sdate}_${edate}_F0.nc #concatnate along record dimension using NCO
	        break
	    fi
	done	

}
export -f concat_scm

parallel concat_scm ::: $(<${SCRIPTS}/vars_all.txt)
