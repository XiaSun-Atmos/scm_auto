import netCDF4
import numpy
import xarray as xr
import os
var_name=os.environ['var']
time_name="time"
yyyy=os.environ['yyyy']
mm=os.environ['mm']
dd=os.environ['dd']
cyc=os.environ['cyc']
suite=os.environ['CCPP_SUITE']

ds=xr.open_mfdataset(suite+'_ICON_'+var_name+'*.nc')
ds_time=xr.open_mfdataset(suite+'_ICON_'+var_name+'_'+yyyy+mm+dd+cyc+'_lat0.nc')

encoding= {var_name: {"zlib": True}}
encoding_time={"time": {"zlib": True,"units":"seconds since 2016-08-11 00:00"}}
ds[var_name].to_netcdf('CCPP_'+suite+'_ICON_'+var_name+'_'+yyyy+mm+dd+cyc+'.nc','w',encoding=encoding)
ds_time[time_name][:].to_netcdf('CCPP_'+suite+'_ICON_'+var_name+'_'+yyyy+mm+dd+cyc+'.nc','a',encoding=encoding_time)


