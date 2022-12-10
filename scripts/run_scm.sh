#!/bin/bash -l

###############################################################
## Abstract:
## Run scm at each grid point in parallel
## CDATE  : current date (YYYYMMDDHH)
## ICON_IC : /full/path/to/ICON/IC
## COMBINE_IC : /full/path/to/combined/IC
## cyc    : current cycle (HH)
## SCRIPTS: /full/path/to/job/scripts
###############################################################
module purge
module use /home/xiasun/MU-MIP/global-workflow-dec1/sorc/ufs_model.fd/modulefiles
module load ufs_orion.intel
export PATH="/home/xiasun/xiasun/anaconda3/bin:$PATH"
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

scm_batch (){
	yyyy=$(echo $CDATE | cut -c1-4)
	mm=$(echo $CDATE | cut -c5-6)
	dd=$(echo $CDATE | cut -c7-8)
	cyc=${cyc:-$(echo $CDATE | cut -c9-10)}
	cd ${SCM_ROOT}/scm/etc/case_config
	cp -r icon_cor_F0_template.nml icon_lat$1_lon$2_$mm$dd$cyc.nml
	sed -i "s/CASENAME/icon_lat$1_lon$2_$mm$dd$cyc/g" icon_lat$1_lon$2_$mm$dd$cyc.nml
	cd ${SCM_ROOT}/scm/data/processed_case_input
	rm -r icon_lat$1_lon$2_${mm}${dd}${cyc}_SCM_driver.nc
	ln -s /home/xiasun/work2_xiasun/mumip/icon_v2.0/proc/${mm}_${dd}_${cyc}/mumip_icon2.5_IO_0.2_${yyyy}$mm$dd.${cyc}_combined_lat$1_lon$2_v2.0.nc icon_lat$1_lon$2_${mm}${dd}${cyc}_SCM_driver.nc
	cd ${SCM_ROOT}/scm/
	rm -rf src_lat$1_lon$2_$mm$dd${cyc}
	mkdir src_lat$1_lon$2_$mm$dd${cyc}
	cd src_lat$1_lon$2_$mm$dd${cyc}
	cp -r ../src/* .
	pwd
	./run_scm.py -c icon_lat$1_lon$2_$mm$dd$cyc -s ${CCPP_SUITE} --n_itt_diag 1 --n_itt_out 1 --run_dir ../run_lat$1_lon$2_$mm$dd$cyc
    if [ -e "${SCM_ROOT}/scm/run_lat$1_lon$2_$mm$dd$cyc/output_icon_lat$1_lon$2_$mm$dd${cyc}_${CCPP_SUITE}/output.nc" ]; then
    	echo "lat$1 lon$2 Success"
	else
		echo "lat$1 lon$2 Fail"
     	./run_scm.py -c icon_lat$1_lon$2_$mm$dd$cyc -s ${CCPP_SUITE} --n_itt_diag 1 --n_itt_out 1 --run_dir ../run_lat$1_lon$2_$mm$dd$cyc
	fi
	rm -rf ${SCM_ROOT}/scm/src_lat$1_lon$2_$mm$dd${cyc}
	rm -r ${SCM_ROOT}/scm/etc/case_config/icon_lat$1_lon$2_$mm$dd${cyc}.nml
	# rm -r /home/xiasun/MU-MIP/mumip-scm-127/scm/data/processed_case_input/icon_lat$1_lon$2_${mm}${dd}${cyc}_SCM_driver.nc
}
export -f scm_batch
# parallel scm_batch ::: {0..199} ::: {0..219}

parallel scm_batch ::: {0..199} ::: {0..219}
