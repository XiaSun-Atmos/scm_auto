# Purpose: concatenate SCM outputs along lat dimension
# author: Xia Sun, CIRES at CU Boulder/NOAA Global Systems Laboratory (Xia.Sun@colorado.edu)
import netCDF4
import numpy
import xarray as xr
import os
from concurrent.futures import ProcessPoolExecutor
import logging
logging.basicConfig(level=logging.INFO)

time_name="time"
yyyy=os.environ['yyyy']
mm=os.environ['mm']
dd=os.environ['dd']
cyc=os.environ['cyc']
suite=os.environ['CCPP_SUITE']
exp=os.environ['EXP']
# suites=['SCM_RAP','SCM_GFS_v17_HR3']
# out_dirs=['RAP','GFSv17_p8']
suites=[suite]
out_dirs=[suite]

vars_all=["T","u","v","qv","pres","tsfc","lhf","shf","t2m","q2m","u10m","v10m","pres_s","qc","qi","ql","sfc_dwn_lw",'pwat',\
"sfc_net_sw","sfc_up_sw","sfc_dwn_sw","dT_dt_phys","dT_dt_micro","dT_dt_deepconv","dT_dt_shalconv","dT_dt_pbl","dT_dt_swrad","dT_dt_lwrad","dT_dt_cgwd","dT_dt_ogwd","dq_dt_phys","dq_dt_micro","dq_dt_shalconv",\
"dq_dt_deepconv","dq_dt_pbl","du_dt_phys","du_dt_pbl","du_dt_deepconv","du_dt_shalconv","du_dt_ogwd","du_dt_cgwd","dv_dt_phys","dv_dt_shalconv","dv_dt_cgwd","dv_dt_deepconv",\
"dv_dt_ogwd","dv_dt_pbl","tprcp_accum","ice_accum","snow_accum","graupel_accum","conv_prcp_accum","v_force_tend","u_force_tend","T_force_tend","qv_force_tend",\
"max_cloud_fraction","rad_cloud_fraction","rad_cloud_swp","rad_cloud_rwp","rad_cloud_iwp","rad_cloud_lwp","toa_total_albedo","dcnv_prcp_inst","mp_prcp_inst","scnv_prcp_inst","tprcp_inst"]
scm_results=os.environ['SCM_RESULTS']
vars_n=len(vars_all)

def process_task(task_id):
    var_name=vars_all[task_id]
    for j in range(1):
        files=scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/output_all/'+var_name+'/SCM_*.nc'
        output_path = scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/output_all/CCPP_'+suites[j]+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'.nc'

        if os.path.isfile(output_path):
            os.remove(output_path)
        else:
            pass
        # Combine using coordinates (lat/lon)
        ds_combined = xr.open_mfdataset(
            files,
            combine="by_coords",
            engine="netcdf4",
            chunks={}
        )
        ds_combined.to_netcdf(output_path)
        ds_combined.close()
    return

if __name__ == "__main__":
    with ProcessPoolExecutor(max_workers=35) as executor:
        task_ids = range(0, vars_n)
        results = list(executor.map(process_task, task_ids))

    print("Done.")
