#!/bin/bash -x
###############################################################
## Abstract:
## Combine ICON ic datafiles for a consecutive of 9 hours
## CDATE  : current date (YYYYMMDDHH)
## ICON_IC : /full/path/to/ICON/IC
## COMBINE_IC : /full/path/to/combined/IC
## cyc    : current cycle (HH)]
## author: Xia Sun, CIRES at CU Boulder/NOAA Global Systems Laboratory (Xia.Sun@colorado.edu)
###############################################################

export PATH="To/Your/Python/DIR"


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


# 2016091015 is the last time cycle, do 6 hr simulation due to ICs ending time
if [ "$yyyy$mm$dd${cyc}" = "2016091015" ]; then
	rm -rf mumip_${EXP}${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_${cyc6}_combined_v2.0.nc
	ncrcat mumip_${EXP}${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_v2.0.nc mumip_${EXP}${GRID}_IO_0.2_$yyyy3$mm3$dd3.${cyc3}_v2.0.nc mumip_${EXP}${GRID}_IO_0.2_$yyyy6$mm6$dd6.${cyc6}_v2.0.nc mumip_${EXP}${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_${cyc6}_combined_v2.0.nc 

	mv mumip_${EXP}${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_${cyc6}_combined_v2.0.nc ${COMBINE_IC}/mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc

	cd ${COMBINE_IC}
	cp -r ${SCRIPTS}/to_dephy_from_mumip_${EXP}_combined_fixw_6hr.bash to_dephy_from_mumip_${EXP}_combined_$yyyy$mm$dd${cyc}.bash
	chmod u+x to_dephy_from_mumip_${EXP}_combined_$yyyy$mm$dd${cyc}.bash
# Convert ICON forcing to DEPHY format
	./to_dephy_from_mumip_${EXP}_combined_$yyyy$mm$dd${cyc}.bash mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc $yyyy$mm$dd${cyc}0000 $yyyy6$mm6$dd6${cyc6}0000
	filename="mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc"
	export filename

# Precalculates vertical advective forcing and adds back to the horizontal advection terms
	python ${SCRIPTS}/icon_vadv_workflow.py 
	ncks -A -v qv_vadv,ta_vadv,ua_vadv,va_vadv,rt_vadv,qt_vadv,theta_vadv,thetal_vadv total_advection_mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc
	ncap2 -s 'tnqv_adv=tnqv_adv+qv_vadv' -s 'tnta_adv=tnta_adv+ta_vadv' -s 'tnua_adv=tnua_adv+ua_vadv' -s 'tnva_adv=tnva_adv+va_vadv'  -s 'tnqt_adv=tnqt_adv+qt_vadv' -s 'tnrt_adv=tnrt_adv+rt_vadv' -s 'tntheta_adv=tntheta_adv+theta_vadv' -s 'tnthetal_adv=tnthetal_adv+thetal_vadv' mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc -O mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_fulladv.nc
	ncatted -h -a forc_wa,global,m,i,0 mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_fulladv.nc -O mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_fulladv.nc

	rm -rf to_dephy_from_mumip_${EXP}_combined_$yyyy$mm$dd${cyc}.bash total_advection_mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc mumip_${EXP}${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_${cyc6}_combined_v2.0.nc
else
# Other time stamps combined 9 hour IC
	rm -rf mumip_${EXP}${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_${cyc9}_combined_v2.0.nc
	ncrcat mumip_${EXP}${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_v2.0.nc mumip_${EXP}${GRID}_IO_0.2_$yyyy3$mm3$dd3.${cyc3}_v2.0.nc mumip_${EXP}${GRID}_IO_0.2_$yyyy6$mm6$dd6.${cyc6}_v2.0.nc mumip_${EXP}${GRID}_IO_0.2_$yyyy9$mm9$dd9.${cyc9}_v2.0.nc mumip_${EXP}${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_${cyc9}_combined_v2.0.nc 

	mv mumip_${EXP}${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_${cyc9}_combined_v2.0.nc ${COMBINE_IC}/mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc

	cd ${COMBINE_IC}
	cp -r ${SCRIPTS}/to_dephy_from_mumip_${EXP}_combined_fixw.bash to_dephy_from_mumip_${EXP}_combined_$yyyy$mm$dd${cyc}.bash
	chmod u+x to_dephy_from_mumip_${EXP}_combined_$yyyy$mm$dd${cyc}.bash
# Convert ICON forcing to DEPHY format
	./to_dephy_from_mumip_${EXP}_combined_$yyyy$mm$dd${cyc}.bash mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc $yyyy$mm$dd${cyc}0000 $yyyy9$mm9$dd9${cyc9}0000
	filename="mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc"
	export filename

# Precalculates vertical advective forcing and adds back to the horizontal advection terms
	python ${SCRIPTS}/icon_vadv_workflow.py 
	ncks -A -v qv_vadv,ta_vadv,ua_vadv,va_vadv,rt_vadv,qt_vadv,theta_vadv,thetal_vadv total_advection_mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc
	ncap2 -s 'tnqv_adv=tnqv_adv+qv_vadv' -s 'tnta_adv=tnta_adv+ta_vadv' -s 'tnua_adv=tnua_adv+ua_vadv' -s 'tnva_adv=tnva_adv+va_vadv'  -s 'tnqt_adv=tnqt_adv+qt_vadv' -s 'tnrt_adv=tnrt_adv+rt_vadv' -s 'tntheta_adv=tntheta_adv+theta_vadv' -s 'tnthetal_adv=tnthetal_adv+thetal_vadv' mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc -O mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_fulladv.nc
	ncatted -h -a forc_wa,global,m,i,0 mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_fulladv.nc -O mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined_fulladv.nc

	rm -rf to_dephy_from_mumip_${EXP}_combined_$yyyy$mm$dd${cyc}.bash total_advection_mumip_${EXP}_${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_combined.nc mumip_${EXP}${GRID}_IO_0.2_$yyyy$mm$dd.${cyc}_${cyc9}_combined_v2.0.nc
fi
exit
