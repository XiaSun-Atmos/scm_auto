#!/bin/bash -x
###############################################################
## Abstract:
## Split ICON IC to each grid points & 
## Convert to DEPHY format
## CDATE  : current date (YYYYMMDDHH)
## ICON_IC : /full/path/to/ICON/IC
## COMBINE_IC : /full/path/to/combined/IC
## cyc    : current cycle (HH)
## SCRIPTS: /full/path/to/job/scripts
###############################################################
export PATH="/home/xiasun/xiasun/anaconda3/bin:$PATH"
export PATH="/work/noaa/gmtb/xiasun/MU-MIP/tools/gnu_parallel/bin:$PATH"
module load nco

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


cd /home/xiasun/work2_xiasun/mumip/icon_v2.0/proc
mkdir ${mm}_${dd}_${cyc}
cd ${mm}_${dd}_${cyc}
cp -r ${SCRIPTS}/to_dephy_from_mumip_v4.bash .

split_batch (){
	yyyy=$(echo $CDATE | cut -c1-4)
	mm=$(echo $CDATE | cut -c5-6)
	dd=$(echo $CDATE | cut -c7-8)
	cyc=${cyc:-$(echo $CDATE | cut -c9-10)}
	cyc9=$(echo $CDATE_9 | cut -c9-10)
	yyyy9=$(echo $CDATE_9 | cut -c1-4)
	mm9=$(echo $CDATE_9 | cut -c5-6)
	dd9=$(echo $CDATE_9 | cut -c7-8)
	cyc9=$(echo $CDATE_9 | cut -c9-10)

   ncks -d lat,$1,$1 -d lon,$2,$2 ${COMBINE_IC}/mumip_icon2.5_IO_0.2_$yyyy$mm$dd.${cyc}_combined_v2.0.nc mumip_icon2.5_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2_v2.0.nc
   ./to_dephy_from_mumip_v4.bash mumip_icon2.5_IO_0.2_$yyyy$mm$dd.${cyc}_combined_lat$1_lon$2_v2.0.nc $yyyy$mm$dd${cyc}0000 $yyyy9$mm9$dd9${cyc9}0000 
   echo "finish $1 $2"
}
export -f split_batch
parallel split_batch ::: {0..199} ::: {0..219}