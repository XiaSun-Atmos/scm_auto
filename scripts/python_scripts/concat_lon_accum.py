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

ds=xr.open_mfdataset('mumip_scm*.nc')
ds_time=xr.open_mfdataset('mumip_scm*lon0_v2*.nc')
print(ds[var_name][[36],:,:,:])

var=ds[var_name][1:36,:,:,:].sum(dim="time_diag_dim",keep_attrs="true",keepdims="true")  #accumulate 6 hour forecast from forecast start
encoding_var={var_name: {"zlib": True}}

time_accum=ds_time[time_name][[36]]
encoding_time = {time_name: {"zlib": True}}

var.to_netcdf(suite+'_ICON_'+var_name+'_'+yyyy+mm+dd+cyc+'.nc','w',encoding=encoding_var)
time_accum.to_netcdf(suite+'_ICON_'+var_name+'_'+yyyy+mm+dd+cyc+'.nc','a',encoding=encoding_time)
