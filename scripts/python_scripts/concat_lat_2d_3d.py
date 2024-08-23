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
exp=os.environ['EXP']


ds_3hr=xr.open_mfdataset(suite+'_'+exp+'_'+var_name+'*_F3.nc')
ds_time_3hr=xr.open_mfdataset(suite+'_'+exp+'_'+var_name+'*lat0_F3.nc')

encoding= {var_name: {"zlib": True}}
encoding_time={"time": {"zlib": True,"units":"seconds since 2016-08-11 00:00"}}
ds_3hr[var_name].to_netcdf('CCPP_'+suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_F3.nc','w',encoding=encoding)
ds_time_3hr[time_name][:].to_netcdf('CCPP_'+suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_F3.nc','a',encoding=encoding_time)


ds_6hr=xr.open_mfdataset(suite+'_'+exp+'_'+var_name+'*_F6.nc')
ds_time_6hr=xr.open_mfdataset(suite+'_'+exp+'_'+var_name+'*lat0_F6.nc')
ds_6hr[var_name].to_netcdf('CCPP_'+suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_F6.nc','w',encoding=encoding)
ds_time_6hr[time_name][:].to_netcdf('CCPP_'+suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_F6.nc','a',encoding=encoding_time)

ic_vars=["T","u","v","qv","pres"]
if var_name in ic_vars:
	ds_0hr=xr.open_mfdataset(suite+'_'+exp+'_'+var_name+'*_F0.nc')
	ds_time_0hr=xr.open_mfdataset(suite+'_'+exp+'_'+var_name+'*lat0_F0.nc')
	ds_0hr[var_name].to_netcdf('CCPP_'+suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_F0.nc','w',encoding=encoding)
	ds_time_0hr[time_name][:].to_netcdf('CCPP_'+suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_F0.nc','a',encoding=encoding_time)
else:
	pass