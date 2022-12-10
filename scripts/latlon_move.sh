#!/bin/bash -l

###############################################################
## Abstract:
## Add lat and lon dimension to CCPP SCM output and move to 
## another directory for future concatenate
## CDATE  : current date (YYYYMMDDHH)
## ICON_IC : /full/path/to/ICON/IC
## COMBINE_IC : /full/path/to/combined/IC
## cyc    : current cycle (HH)
## SCRIPTS: /full/path/to/job/scripts
###############################################################

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

add_dimension_mv (){
	yyyy=$(echo $CDATE | cut -c1-4)
	mm=$(echo $CDATE | cut -c5-6)
	dd=$(echo $CDATE | cut -c7-8)
	cyc=${cyc:-$(echo $CDATE | cut -c9-10)}
	echo $1 $2

	cd ${RUN_DIR}/run_lat$1_lon$2_$mm$dd$cyc/output_icon_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}
	rm -r output_latlon.nc
	rm -r *.tmp
	pwd

    lat_val=`ncdump -v lat /home/xiasun/work2_xiasun/mumip/icon_v2.0/proc/${mm}_${dd}_${cyc}/mumip_icon2.5_IO_0.2_${yyyy}$mm$dd.${cyc}_combined_lat$1_lon$2_v2.0.nc | tail -n 2 | head -n 1 | sed -e 's/lat = \(.*\) ;/\1/' |sed 's/ //g'`
	echo "$lat_val"
	# lat_val=`echo ${lat_val} | xargs`
    lon_val=`ncdump -v lon /home/xiasun/work2_xiasun/mumip/icon_v2.0/proc/${mm}_${dd}_${cyc}/mumip_icon2.5_IO_0.2_${yyyy}$mm$dd.${cyc}_combined_lat$1_lon$2_v2.0.nc | tail -n 2 | head -n 1 | sed -e 's/lon = \(.*\) ;/\1/' |sed 's/ //g'`
	# lon_val=`echo ${lon_val} | xargs`
	echo "${lon_val}"
	# echo "${lat_val}"
	ncap2 -h -s 'defdim("lat",1);lat[lat]='${lat_val}';lat@long_name="latitude";lat@standard_name="latitude";lat@units="degrees_north"' output.nc  -O output_latlon.nc
	ncap2 -h -s 'defdim("lon",1);lon[lon]='${lon_val}';lon@long_name="longitude";lon@standard_name="longitude";lon@units="degrees_east"' output_latlon.nc   -O output_latlon.nc
	while read line; do
     # echo "$line"
	 ncap2 -h -s "$line" output_latlon.nc -O output_latlon.nc
	done < $SCRIPTS/for_ncap2_127.txt
	ncwa -a hor_dim_layer output_latlon.nc -O output_latlon.nc #remove hor_dim_layer
	mkdir ${SCM_RESULTS}/v2.0_${CCPP_SUITE}/${mm}_${dd}_${cyc}
	mv ${RUN_DIR}/run_lat$1_lon$2_$mm$dd$cyc/output_icon_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}/output_latlon.nc ${SCM_RESULTS}/v2.0_${CCPP_SUITE}/${mm}_${dd}_${cyc}/mumip_scm_${yyyy}$mm$dd.${cyc}_lat$1_lon$2_v2.0_${CCPP_SUITE}.nc 
	if [ -e "${RUN_DIR}/run_lat$1_lon$2_$mm$dd$cyc/output_icon_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}/output_latlon.nc" ]; then
    	echo "lat$1 lon$2 Fail"
    	mv ${RUN_DIR}/run_lat$1_lon$2_$mm$dd$cyc/output_icon_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}/output_latlon.nc ${SCM_RESULTS}/v2.0_${CCPP_SUITE}/${mm}_${dd}_${cyc}/mumip_scm_${yyyy}$mm$dd.${cyc}_lat$1_lon$2_v2.0_${CCPP_SUITE}.nc 
	else
		echo "lat$1 lon$2 Success"
		rm -rf ${RUN_DIR}/run_lat$1_lon$2_$mm$dd$cyc
	fi
}
export -f add_dimension_mv
parallel add_dimension_mv ::: {0..199} ::: {0..219}

