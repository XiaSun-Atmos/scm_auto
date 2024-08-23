import netCDF4
import numpy
import xarray as xr
import os
var_name=os.environ['var']
time_name=os.environ['time_inst']
yyyy=os.environ['yyyy']
mm=os.environ['mm']
dd=os.environ['dd']
cyc=os.environ['cyc']
suite=os.environ['CCPP_SUITE']
exp=os.environ['EXP']
nlat=os.environ['nlat']

twod_vars=["tprcp_accum","ice_accum","snow_accum","graupel_accum","conv_prcp_accum"]
# rad_vars=["max_cloud_fraction"]

ds=xr.open_mfdataset('mumip_'+exp+'_scm*.nc')
ds_time=xr.open_mfdataset('mumip_'+exp+'_scm*lon0*.nc')
# print(ds[var_name][[36],:,:,:])

if var_name in twod_vars:
	var_6hr=ds[var_name][1:36,:,:].sum(dim="time_diag_dim",keep_attrs="true",keepdims="true")  #accumulate 6 hour forecast from forecast start
	var_3hr=ds[var_name][1:18,:,:].sum(dim="time_diag_dim",keep_attrs="true",keepdims="true")  #accumulate 3 hour forecast from forecast start
else:
	var_6hr=ds[var_name][1:36,:,:,:].sum(dim="time_diag_dim",keep_attrs="true",keepdims="true")  #accumulate 6 hour forecast from forecast start
	var_3hr=ds[var_name][1:18,:,:,:].sum(dim="time_diag_dim",keep_attrs="true",keepdims="true")  #accumulate 6 hour forecast from forecast start



encoding_var={var_name: {"zlib": True}}

time_accum_6hr=ds_time[time_name][[36]]
time_accum_3hr=ds_time[time_name][[18]]
encoding_time = {time_name: {"zlib": True}}

var_3hr.to_netcdf(suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_F3.nc','w',encoding=encoding_var)
time_accum_3hr.to_netcdf(suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_F3.nc','a',encoding=encoding_time)

var_6hr.to_netcdf(suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_F6.nc','w',encoding=encoding_var)
time_accum_6hr.to_netcdf(suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_F6.nc','a',encoding=encoding_time)