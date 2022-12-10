#!/bin/bash -x
###############################################################
## Abstract:
## Combine ICON ic datafiles for a consecutive of 9 hours
## CDATE  : current date (YYYYMMDDHH)
## ICON_IC : /full/path/to/ICON/IC
## COMBINE_IC : /full/path/to/combined/IC
## cyc    : current cycle (HH)
###############################################################

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

module load nco
cd $ICON_IC
ncrcat mumip_icon2.5_IO_0.2_$yyyy$mm$dd.${cyc}_v2.0.nc mumip_icon2.5_IO_0.2_$yyyy3$mm3$dd3.${cyc3}_v2.0.nc mumip_icon2.5_IO_0.2_$yyyy6$mm6$dd6.${cyc6}_v2.0.nc mumip_icon2.5_IO_0.2_$yyyy9$mm3$dd9.${cyc9}_v2.0.nc mumip_icon2.5_IO_0.2_$yyyy$mm$dd.${cyc}_${cyc9}_combined_v2.0.nc 
mv mumip_icon2.5_IO_0.2_$yyyy$mm$dd.${cyc}_${cyc9}_combined_v2.0.nc ${COMBINE_IC}/mumip_icon2.5_IO_0.2_$yyyy$mm$dd.${cyc}_combined_v2.0.nc 
