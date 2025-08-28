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
## author: Xia Sun, CIRES at CU Boulder/NOAA Global Systems Laboratory (Xia.Sun@colorado.edu)

###############################################################


module load nco
module load parallel

vars=("T" "u" "v" "qv" "pres" "tsfc" "lhf" "shf" "t2m" "q2m" "u10m" "v10m" "pres_s" "qc" "qi" "ql" "sfc_dwn_lw" 'pwat' \
"sfc_net_sw" "sfc_up_sw" "sfc_dwn_sw" "dT_dt_phys" "dT_dt_micro" "dT_dt_deepconv" "dT_dt_shalconv" "dT_dt_pbl" "dT_dt_swrad" "dT_dt_lwrad" "dT_dt_cgwd" "dT_dt_ogwd" "dq_dt_phys" "dq_dt_micro" "dq_dt_shalconv" \
"dq_dt_deepconv" "dq_dt_pbl" "du_dt_phys" "du_dt_pbl" "du_dt_deepconv" "du_dt_shalconv" "du_dt_ogwd" "du_dt_cgwd" "dv_dt_phys" "dv_dt_shalconv" "dv_dt_cgwd" "dv_dt_deepconv" \
"dv_dt_ogwd" "dv_dt_pbl" "tprcp_accum" "ice_accum" "snow_accum" "graupel_accum" "conv_prcp_accum" "v_force_tend" "u_force_tend" "T_force_tend" "qv_force_tend" \
"max_cloud_fraction" "rad_cloud_fraction" "rad_cloud_swp" "rad_cloud_rwp" "rad_cloud_iwp" "rad_cloud_lwp" "toa_total_albedo" "dcnv_prcp_inst" "mp_prcp_inst" "scnv_prcp_inst" "tprcp_inst")

dir=${CCPP_SUITE}
export dir
concat_scm (){

  var=$1
  echo "Processing ${var}"
  mkdir -p ${CONCATE_OUTPUT}/${var}
  cd ${CONCATE_OUTPUT}/${var}

  for file in ${SCM_RESULTS}/${dir}/0*/output_all/CCPP_${CCPP_SUITE}_icon_${var}_2016*.nc; do
    base=$(basename "$file")  # get the parent folder name (optional)
    echo "Processing $file -> ${base}_a.nc"
    ncks -h --mk_rec_dmn init_time "$file" -O -o "${base}_a.nc"
  done
   ncrcat -h -x -v Times CCPP_${CCPP_SUITE}_icon_${var}_20160*.nc_a.nc CCPP_${CCPP_SUITE}_icon_${var}.nc
   rm -rf CCPP_${CCPP_SUITE}_icon_${var}_20160*.nc_a.nc 

}
export -f concat_scm
parallel -j 35 concat_scm ::: "${vars[@]}"
