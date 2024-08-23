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
# export PATH="/work2/noaa/gmtb/xiasun/anaconda3/bin:$PATH"

ulimit -u unlimited
ulimit -s unlimited
ulimit -a unlimited
module purge
module use /glade/derecho/scratch/xiasun/mumip/scm/ccpp-scm//scm/etc/modules
module load derecho_intel
module load nco
export PATH="/work/noaa/gmtb/xiasun/MU-MIP/tools/gnu_parallel/bin:$PATH"
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

export yyyy
export mm
export dd
export cyc
export yyyy9
export mm9
export dd9
export cyc9

suite1=SCM_RAP
suite2=SCM_GFS_v17_HR3

export suite1
export suite2
# cd ${SPLIT_IC}
# mkdir ${mm}_${dd}_${cyc}
# cd ${mm}_${dd}_${cyc}
# cp -r ${SCRIPTS}/to_dephy_from_mumip_v5.bash .
# chmod u+x to_dephy_from_mumip_v5.bash

minsize=50000

# make dirs for IC

mkdir ${SPLIT_IC}/${mm}_${dd}_${cyc}

# make dirs for scm outputs
# mkdir ${SCM_RESULTS}/${mm}_${dd}_${cyc}
# mkdir ${SCM_RESULTS}/${mm}_${dd}_${cyc}/${suite1}
# mkdir ${SCM_RESULTS}/${mm}_${dd}_${cyc}/${suite2}

split_ic (){
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

	######## Retrieve IC at lat and lon ##########
	# cd ${SPLIT_IC}
	# mkdir ${mm}_${dd}_${cyc}
	# cd ${mm}_${dd}_${cyc}
	mkdir ${SPLIT_IC}/${mm}_${dd}_${cyc}/lat_$1
	cd ${SPLIT_IC}/${mm}_${dd}_${cyc}/lat_$1
    rm -r mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2.nc
    ncks -h -d lat,$1 -d lon,$2 ${COMBINE_IC}/mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2.nc
	ncwa -h -a lon,lat mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2.nc -O mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2.nc
	###   global attributes   ###
	z0=`ncdump -v z0 mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2.nc | tail -n 2 | head -n 1 | cut -d ';' -f 1`
	zorog=`ncdump -v orog mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2.nc | tail -n 2 | head -n 1 | cut -d ';' -f 1`
	# zorog=$(($zorog))
	z0=`echo ${z0} | xargs`
	zorog=`echo ${zorog} | xargs`

	ncatted -h -a zorog,global,c,f,0.0 -a z0,global,c,f,0.0 \
	mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2.nc -O mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2.nc

	
	actsize=`wc -c <"mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat${1}_lon${2}.nc"`  # check if python work properly
	echo $actsize
	echo $minsize

	if [[ $actsize -lt $minsize ]]; then
    	echo "lat$1 lon$2 Fail"
	else
	 	echo "finish split_ic for lat$1 lon$2"
	fi

	# while [[ $actsize -lt $minsize ]]
	# do
	# 	echo "reruning split_ic for $1 $2"
   	# 	rm -r mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2.nc
   	# 	ncks -d lat,$1,$1 -d lon,$2,$2 ${COMBINE_IC}/mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2.nc
 	# 	./to_dephy_from_mumip_v5.bash mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2.nc $yyyy$mm$dd${cyc}0000 $yyyy9$mm9$dd9${cyc9}0000
 	# 	actsize=`wc -c <"mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat${1}_lon${2}.nc"`
 	# done
 	unset z0
	unset zorog
	unset actsize

 	echo "finish split_ic for $1 $2"

}
export -f split_ic
# time parallel -u scm_auto_batch ::: {0..5} ::: {0..5}
time parallel -j 40 -u split_ic ::: {0..199} ::: {0..219}

