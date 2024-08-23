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

ic_vars=["T","u","v","qv","pres"]
twod_vars=["tsfc","lhf","shf","t2m","q2m","u10m","v10m"]
rad_vars=["max_cloud_fraction","rad_cloud_swp","rad_cloud_rwp","rad_cloud_iwp","rad_cloud_lwp","rad_cloud_fraction"]
ds=xr.open_mfdataset('mumip_'+exp+'_scm*.nc')
ds_time=xr.open_mfdataset('mumip_'+exp+'_scm*lon0*.nc')
# print(ds[var_name][[36],:,:,:])

if var_name in twod_vars:
	var_6hr=ds[var_name][[36],:,:] #the 6th hour forecast, 2D
	var_3hr=ds[var_name][[18],:,:] #the 3rd hour forecast, 2D


elif var_name in rad_vars:
	var_3hr=ds[var_name][[8],:,:]
	var_3hr[:,:,:]=(ds[var_name][[8],:,:]+ds[var_name][[9],:,:])/2. #the 6th hour forecast rad time steps is two times of dt, so we are averaging the adjacent time steps 2D
	var_6hr=ds[var_name][[17],:,:]
	var_6hr[:,:,:]=(ds[var_name][[17],:,:]+ds[var_name][[18],:,:])/2.  #the 3rd hour forecast rad time steps, 2D

else:
	var_6hr=ds[var_name][[36],:,:,:] #the 6th hour forecast, 3D
	var_3hr=ds[var_name][[18],:,:,:] #the 3rd hour forecast, 3D




encoding_var={var_name: {"zlib": True}}

time_inst_6hr=ds_time[time_name][[36]]
time_inst_3hr=ds_time[time_name][[18]]

encoding_time = {"time_inst": {"zlib": True}}

var_3hr.to_netcdf(suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_F3.nc','w',encoding=encoding_var)
time_inst_3hr.to_netcdf(suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_F3.nc','a',encoding=encoding_time)

var_6hr.to_netcdf(suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_F6.nc','w',encoding=encoding_var)
time_inst_6hr.to_netcdf(suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_F6.nc','a',encoding=encoding_time)

if var_name in ic_vars:
	var_0hr=ds[var_name][[0],:,:,:]
	time_inst_0hr=ds_time[time_name][[0]]
	var_0hr.to_netcdf(suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_F0.nc','w',encoding=encoding_var)
	time_inst_0hr.to_netcdf(suite+'_'+exp+'_'+var_name+'_'+yyyy+mm+dd+cyc+'_lat'+nlat+'_F0.nc','a',encoding=encoding_time)
else:
	pass


