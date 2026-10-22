# Purpose: concatenate SCM outputs along lon dimension
# author: Xia Sun, CIRES at CU Boulder/NOAA Global Systems Laboratory (Xia.Sun@colorado.edu)

import netCDF4
import numpy as np
import xarray as xr
import os
import pandas as pd
from concurrent.futures import ProcessPoolExecutor
import gc

yyyy=os.environ['yyyy']
mm=os.environ['mm']
dd=os.environ['dd']
cyc=os.environ['cyc']
suite=os.environ['CCPP_SUITE']

scm_results=os.environ['SCM_RESULTS']

suites=[suite]
out_dirs=[suite]

twod_vars=["tsfc","lhf","shf","t2m","q2m","u10m","v10m","pres_s","max_cloud_fraction","sfc_dwn_lw",\
"sfc_net_sw","sfc_up_sw","sfc_dwn_sw","tprcp_accum","ice_accum","snow_accum","graupel_accum","conv_prcp_accum",\
'pwat','toa_total_albedo',"dcnv_prcp_inst","mp_prcp_inst","scnv_prcp_inst","tprcp_inst"]

vars_to_store=["T","u","v","qv","pres","tsfc","lhf","shf","t2m","q2m","u10m","v10m","pres_s","qc","qi","ql","sfc_dwn_lw",'pwat',\
"sfc_net_sw","sfc_up_sw","sfc_dwn_sw","dcnv_prcp_inst","mp_prcp_inst","scnv_prcp_inst","tprcp_inst"]
rad_vars=["max_cloud_fraction","rad_cloud_fraction","rad_cloud_swp","rad_cloud_rwp","rad_cloud_iwp","rad_cloud_lwp","toa_total_albedo"]
vars_total=["T","u","v","qv","pres","tsfc","lhf","shf","t2m","q2m","u10m","v10m","pres_s","max_cloud_fraction","rad_cloud_swp",\
"rad_cloud_rwp","rad_cloud_iwp","rad_cloud_lwp","rad_cloud_fraction"]

accum_vars=["dT_dt_phys","dT_dt_micro","dT_dt_deepconv","dT_dt_shalconv","dT_dt_pbl","dT_dt_swrad","dT_dt_lwrad","dT_dt_cgwd","dT_dt_ogwd","dq_dt_phys","dq_dt_micro","dq_dt_shalconv",\
"dq_dt_deepconv","dq_dt_pbl","du_dt_phys","du_dt_pbl","du_dt_deepconv","du_dt_shalconv","du_dt_ogwd","du_dt_cgwd","dv_dt_phys","dv_dt_shalconv","dv_dt_cgwd","dv_dt_deepconv",\
"dv_dt_ogwd","dv_dt_pbl","tprcp_accum","ice_accum","snow_accum","graupel_accum","conv_prcp_accum","v_force_tend","u_force_tend","T_force_tend","qv_force_tend"]

def process_task(task_id):

    nlat=str(task_id)

    for j in range(1):

        ds_scm=xr.open_mfdataset(scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/lat_'+nlat+'/mumip_icon_scm*.nc')

        lat=ds_scm["lat"]
        lon=ds_scm["lon"]
        levels=np.arange(0,127)
        forecast_hour=np.arange(0,7)
        vars_all=ds_scm[vars_to_store].isel(time_inst_dim=[0, 6, 12,18,24,30,36])
        if f"{yyyy}{mm}{dd}{cyc}" == "2016091015":
            vars_rad=ds_scm[rad_vars].isel(time_rad_dim=[2, 3, 5,6,8,9, 11, 12 ,14,15,17,17])
        else:
            vars_rad=ds_scm[rad_vars].isel(time_rad_dim=[2, 3, 5,6,8,9, 11, 12 ,14,15,17,18])
        vars_accum=ds_scm[accum_vars].isel(time_diag_dim=slice(None))
        ds_scm.close()

        init_time_str=yyyy+'-'+mm+'-'+dd+' '+cyc+':00'
        init_time_dt=pd.to_datetime(init_time_str)
        # Reference time for the units
        reference_time_dt = pd.to_datetime("2016-08-11 00:00")

        # Compute offset in seconds
        delta_seconds = (init_time_dt - reference_time_dt).total_seconds()
        # print(f"Seconds since reference: {delta_seconds}")

        # Make it an array of shape (1,) if you want the init_time dimension
        init_time_numeric = np.array([delta_seconds])

        Times = xr.DataArray(
            np.array([init_time_str], dtype='S'),  # store as bytes (NetCDF safe)
            dims=['init_time'],
            name='Times'
        )

        # processing accumulation vars with time_diag_dim
        forecast_hour=np.arange(1,7)
        for var_name in accum_vars:
            os.makedirs(scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/output_all/'+var_name, exist_ok=True)
            file_path=scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/output_all/'+var_name+'/'+suites[j]+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_'+var_name+'.nc'
            if os.path.isfile(file_path):
                os.remove(file_path)
            else:
                pass
            print(file_path)

            # Define accumulation steps
            time_steps = [6, 12, 18, 24, 30, 36]
            accumulated = []

            if var_name in ["v_force_tend","u_force_tend","T_force_tend","qv_force_tend"]:
                for t in time_steps:
                    acc = vars_accum[var_name].isel(time_inst_dim=slice(1, t)).sum(dim="time_inst_dim")
                    accumulated.append(acc*600.)
     
            elif  var_name in ["tprcp_accum","ice_accum","snow_accum","graupel_accum","conv_prcp_accum"]:
                for t in time_steps:
                    acc = vars_accum[var_name].isel(time_diag_dim=slice(1, t)).sum(dim="time_diag_dim")
                    accumulated.append(acc)
       
            else:
                for t in time_steps:
                    acc = vars_accum[var_name].isel(time_diag_dim=slice(1, t)).sum(dim="time_diag_dim")
                    accumulated.append(acc*600.)
    
            accumulated = xr.concat(accumulated, dim="time_diag_dim")
            print(accumulated)
            if 'hor_dim_layer' in accumulated.dims:
                accumulated = accumulated.squeeze(dim='hor_dim_layer')

            # Combine into a new DataArray along a new time dimension

            accumulated=accumulated.expand_dims({'init_time': 1})
            accumulated= accumulated.assign_attrs(vars_accum[var_name].attrs)

            if "description" in accumulated.attrs:
                accumulated.attrs["description"] = "accumulated " + accumulated.attrs["description"]+ " since "+init_time_str
            else:
                pass

            if "units" in accumulated.attrs:
                if accumulated.attrs["units"] == "m s-2":
                    accumulated.attrs["units"] = "m s-1"
                elif accumulated.attrs["units"] == "K s-1":
                    accumulated.attrs["units"] = "K"
                elif accumulated.attrs["units"] == "kg kg-1 s-1":
                    accumulated.attrs["units"] = "kg kg-1"
                else:
                    pass

            else:
                pass
            print(accumulated.attrs)

            if var_name in twod_vars:

                ds = xr.Dataset(
                data_vars={
                    var_name: (["init_time", "forecast_hour", "lat", "lon"], accumulated.data, accumulated.attrs),
                    "Times":(["init_time"], Times.data),
                    },
                coords={
                    "init_time": (
                        "init_time",
                        init_time_numeric,
                        {
                        "units": "seconds since 2016-08-11 00:00:00",
                        "calendar": "standard"
                        }),
                    "forecast_hour": forecast_hour,
                    "lat": lat.astype('float32'),
                    "lon": lon.astype('float32'),
                    },
                attrs={
                    "description": "Example dataset with init_time and multiple variables"
                    }
                )

                encoding = {
                var_name: {
                    'zlib': True,
                    'complevel': 4,
                    }
                    }
            else:
                ds = xr.Dataset(
                data_vars={
                    var_name: (["init_time", "forecast_hour", "level","lat", "lon"], accumulated.data, accumulated.attrs),
                    "Times":(["init_time"], Times.data),
                    },
                coords={
                    "init_time": (
                        "init_time",
                        init_time_numeric,
                        {
                        "units": "seconds since 2016-08-11 00:00:00",
                        "calendar": "standard"
                        }),
                    "forecast_hour": forecast_hour,
                    "level": levels,
                    "lat": lat.astype('float32'),
                    "lon": lon.astype('float32'),
                    },
                attrs={
                    "description": "Example dataset with init_time and multiple variables"
                    }
                )

                encoding = {
                var_name: {
                    'zlib': True,
                    'complevel': 4,
                    }
                    }           

            ds.to_netcdf(scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/output_all/'+var_name+'/'+suites[j]+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_'+var_name+'.nc','w')
            del accumulated
            ds.close()

        del vars_accum





        # processing radiation vars with time_rad_dim
        forecast_hour=np.arange(1,7)
        for var_name in rad_vars:
            os.makedirs(scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/output_all/'+var_name, exist_ok=True)
            print(var_name)
            file_path=scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/output_all/'+var_name+'/'+suites[j]+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_'+var_name+'.nc'
            if os.path.isfile(file_path):
                os.remove(file_path)
            else:
                pass

            # Pairwise mean
            avg_list = []

            for i in range(0, len(vars_rad[var_name].time_rad_dim),2):
                pair = vars_rad[var_name].isel(time_rad_dim=[i, i+1])
                pair_mean = pair.mean(dim="time_rad_dim")
                avg_list.append(pair_mean)

            # Combine along new time dimension
            averaged = xr.concat(avg_list, dim="time_rad_dim")

            if 'hor_dim_layer' in averaged.dims:
                averaged= averaged.squeeze(dim='hor_dim_layer')

            print(averaged.shape)
            print(averaged.dims)
            averaged=averaged.expand_dims({'init_time': 1})
            averaged= averaged.assign_attrs(vars_rad[var_name].attrs)
            if var_name in twod_vars:
                ds = xr.Dataset(
                    data_vars={
                        var_name: (["init_time", "forecast_hour","lat", "lon"], averaged.data,averaged.attrs),
                        "Times":(["init_time"], Times.data),
                    },
                    coords={
                        "init_time": (
                            "init_time",
                            init_time_numeric,
                            {
                            "units": "seconds since 2016-08-11 00:00:00",
                            "calendar": "standard"
                            }),
                        "forecast_hour": forecast_hour,
                        "lat": lat.astype('float32'),
                        "lon": lon.astype('float32'),
                    },
                    attrs={
                        "description": "Example dataset with init_time and multiple variables"
                    }
                )
                encoding = {
                var_name: {
                    'zlib': True,
                    'complevel': 4,
                    }
                    }
            else:
                ds = xr.Dataset(
                    data_vars={
                        var_name: (["init_time", "forecast_hour","levels","lat", "lon"], averaged.data,averaged.attrs),
                        "Times":(["init_time"], Times.data),
                    },
                    coords={
                        "init_time": (
                            "init_time",
                            init_time_numeric,
                            {
                            "units": "seconds since 2016-08-11 00:00:00",
                            "calendar": "standard"
                            }),
                        "forecast_hour": forecast_hour,
                        "level": levels,
                        "lat": lat.astype('float32'),
                        "lon": lon.astype('float32'),
                    },
                    attrs={
                        "description": "Example dataset with init_time and multiple variables"
                    }
                )
                encoding = {
                var_name: {
                    'zlib': True,
                    'complevel': 4,
                    }
                    }        

            ds.to_netcdf(scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/output_all/'+var_name+'/'+suites[j]+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_'+var_name+'.nc','w') 
            del averaged
            ds.close()
            # gc.collect()
        del vars_rad


        #processing instatanous vars with time_inst_dim

        forecast_hour=np.arange(0,7)
        for var_name in vars_to_store:
            os.makedirs(scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/output_all/'+var_name, exist_ok=True)

            file_path=scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/output_all/'+var_name+'/'+suites[j]+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_'+var_name+'.nc'
            if os.path.isfile(file_path):
                os.remove(file_path)
            else:
                pass
            print(var_name)
            pressure=vars_all[var_name].expand_dims({'init_time': 1})
            # If needed, manually copy attributes back (usually not needed, but safe!)
            print(vars_all[var_name].attrs)
            pressure = pressure.assign_attrs(vars_all[var_name].attrs)

            if 'hor_dim_layer' in pressure.dims:
                pressure = pressure.squeeze(dim='hor_dim_layer')

            file_path=scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/output_all/'+var_name+'/'+suites[j]+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_'+var_name+'.nc'
            if os.path.isfile(file_path):
                os.remove(file_path)
            else:
                pass


            if var_name in twod_vars:        

                ds = xr.Dataset(
                    data_vars={
                        var_name: (["init_time", "forecast_hour", "lat", "lon"], pressure.data,pressure.attrs),
                        "Times":(["init_time"], Times.data),
                    },
                    coords={
                        "init_time": (
                            "init_time",
                            init_time_numeric,
                            {
                            "units": "seconds since 2016-08-11 00:00:00",
                            "calendar": "standard"
                            }),
                        "forecast_hour": forecast_hour,
                        "lat": lat.astype('float32'),
                        "lon": lon.astype('float32'),
                    },
                    attrs={
                        "description": "Example dataset with init_time and multiple variables"
                    }
                )
            # elif var_name in rad_vars:

            else:
                ds = xr.Dataset(
                    data_vars={
                        var_name: (["init_time", "forecast_hour", 'level',"lat", "lon"], pressure.data,pressure.attrs),
                        "Times":(["init_time"], Times.data),
                    },
                    coords={
                        "init_time": (
                            "init_time",
                            init_time_numeric,
                            {
                            "units": "seconds since 2016-08-11 00:00:00",
                            "calendar": "standard"
                            }),
                        "forecast_hour": forecast_hour,
                        "level": levels,
                        "lat": lat.astype('float32'),
                        "lon": lon.astype('float32'),
                    },
                    attrs={
                        "description": "Example dataset with init_time and multiple variables"
                    }
                )        

            ds.to_netcdf(scm_results+'/'+out_dirs[j]+'/'+mm+'_'+dd+'_'+cyc+'/output_all/'+var_name+'/'+suites[j]+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_'+var_name+'.nc','w')
            del pressure
            ds.close()

        del vars_all

    return

if __name__ == "__main__":
    task_ids = range(200)


    with ProcessPoolExecutor(max_workers=60) as executor:
        results = list(executor.map(process_task, task_ids))

    print("Done.")
    gc.collect()
