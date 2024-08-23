# purpose: convert ICON format forcing to dephy v1 to drive CCPP SCM, MUMIP project, 2024
# contact: Kathryn Newman, knewman@ucar.edu 
#          Xia Sun, xia.sun@noaa.gov


#!/bin/bash -u


if [ $# -lt 3 ]
  then
  echo 'Incorrect command line'
  echo 'Command line should be: to_dephy_from_mumip.bash FILENAME startDate endDate'
  echo 'Where FILENAME is the name of a MUMIP netCDF file needing conversion to DEPHY v0 and startDate and endDate are in yyyymmddhhmmss'
  exit 1
fi

filename=$1
subname=${filename%%.nc}
echo $subname
startdate=$2
enddate=$3

#setting constants
l_v=2.501e6
c_pd=1005.7

### create t0 (initialization) variables ###
#cut out variables at initial time
ncks -h -d time,0 ${filename} -O init_time_${filename}
#rename time dimension


ncrename -h -d time,t0 init_time_${filename} -O init_time_${filename}
#rename vars
ncrename -h -v u_t,u -v v_t,v -v height_t,height -v ps_t,ps -v pressure_t,pressure -v temp_t,temp \
-v qi_t,qi -v ql_t,ql -v qt_t,qt -v qv_t,qv -v theta_t,theta -v thetal_t,thetal init_time_${filename} -O init_time_${filename}

#create mixing ratio variables from specific humidity variables r approx equal q
# ncap2 -h -s'rl=ql;rv=qv;ri=qi;rt=qt;' init_time.nc -O init_time.nc
ncap2 -h -s'rl=rl_t;rv=rv_t;ri=ri_t;rt=rt_t;' init_time_${filename} -O init_time_${filename} 
#create mixing ratio variables from specific humifity variables
#ncap2 -h -s'rl=ql/(1.0-ql);' init_time.nc -O init_time.nc
#ncap2 -h -s'ri=qi/(1.0-qi);' init_time.nc -O init_time.nc
#ncap2 -h -s'rv=qv/(1.0-qv);' init_time.nc -O init_time.nc
#ncap2 -h -s'rt=qt/(1.0-qt);' init_time.nc -O init_time.nc

#carve out the variables that are required to exist using the initial t0 dimension
ncks -h -v rl,ql,rv,qv,qt,rt,ri,qi,u,v,height,ps,pressure,temp,theta,thetal init_time_${filename} -O init_vars_${filename}

#fix t0 dimension so it is no longer unlimited
ncks -h --fix_rec_dmn t0 init_vars_${filename} -O init_vars_${filename}

### rename time dependent variables ###

ncrename -h -v ps_t,ps_forc -v height_t,height_forc -v pressure_t,pressure_forc \
-v u_t,u_nudging -v v_t,v_nudging -v theta_t,theta_nudging -v thetal_t,thetal_nudging -v temp_t,temp_forc \
-v qi_t,qi_nudging -v ql_t,ql_nudging -v qt_t,qt_nudging -v qv_t,qv_nudging \
-v rl_t,rl_nudging -v ri_t,ri_nudging -v rv_t,rv_nudging -v rt_t,rt_nudging \
${filename} -O ${filename}


#concatenate initial vars file to create final DEPHY v0 file
ncks -h init_vars_${filename} -A ${filename}


echo "start ncatted process"
ncatted -h -a surfaceType,global,c,c,ocean -a surface_forcing_temp,global,o,c,surface_flux -a surface_forcing_wind,global,o,c,z0 \
-a surface_forcing_moisture,global,o,c,surface_flux -a nudging_temp,global,m,i,0 \
${filename} -O ${filename}
echo "surfaceForcing"

#changes for startDate and endDate
yr=${startdate:0:4}
mo=${startdate:4:2}
dy=${startdate:6:2}
hr=${startdate:8:2}
min=${startdate:10:2}
sec=${startdate:12:2}
echo "$sec"
datestring=${yr}'-'${mo}'-'${dy}' '${hr}':'${min}':'${sec}

end_yr=${enddate:0:4}
end_mo=${enddate:4:2}
end_dy=${enddate:6:2}
end_hr=${enddate:8:2}
end_min=${enddate:10:2}
end_sec=${enddate:12:2}

enddate_string=${end_yr}'-'${end_mo}'-'${end_dy}' '${end_hr}':'${end_min}':'${end_sec}

ncap2 -h -s't0=0;' ${filename} -O ${filename}
ncatted -h -O -a units,t0,o,c,"seconds since ${datestring}" ${filename} 

echo "rename start_date and end_date"

ncrename -h -a global@startDate,start_date -a global@endDate,end_date ${filename} -O ${filename}

# ncrename -h -a global@endDate,end_date ${filename} -O ${filename}
ncatted -h -a start_date,global,m,c,"${datestring}" -a end_date,global,m,c,"${enddate_string}" \
-a nudging_v,global,m,i,0 -a nudging_u,global,m,i,0 -a nudging_rt,global,m,i,0 -a nudging_rv,global,m,i,0 \
-a nudging_qt,global,m,i,0 -a nudging_qv,global,m,i,0 -a nudging_theta,global,m,i,0 -a nudging_thetal,global,m,i,0 \
-a nudging_temp,global,m,i,0 -a forc_w,global,m,i,1 -a forc_geo,global,m,i,1 \
${filename} -O ${filename} 


#change time 
ncap2 -h -s 'time(:)={0,10800,21600,32400}' ${filename} -O ${filename} 
ncatted -h -O -a units,time,o,c,"seconds since ${datestring}" ${filename}
# add tke and set to 0
ncap2 -h -s 'tke[t0, lev, lat, lon]=0.' ${filename} -O ${filename} 

#flip vertical dimension of all variables
ncpdq -h -a -lev ${filename} -O ${filename}
rm -f init_vars_${filename}
rm -f init_time_${filename}

#DEPHY v0-DEPHYv1 extra processing - Xia, Apr 2024
#some of the changes below can be applied to above, we can work on this later
# vars renaming
ncrename -h -v pressure,pa -v temp,ta -v u,ua -v v,va -v thetal_adv,tnthetal_adv -v rv_adv,tnrv_adv -v rt_adv,tnrt_adv -v qt_adv,tnqt_adv -v qv_adv,tnqv_adv -v height_forc,zh_forc -v pressure_forc,pa_forc \
-v qi_nudging,qi_nud -v ql_nudging,ql_nud -v qt_nudging,qt_nud -v qv_nudging,qv_nud -v ri_nudging,ri_nud -v rl_nudging,rl_nud -v rt_nudging,rt_nud -v rv_nudging,rv_nud \
-v temp_adv,tnta_adv -v temp_forc,ta_forc -v theta_adv,tntheta_adv -v thetal_nudging,thetal_nud -v theta_nudging,theta_nud \
-v u_adv,tnua_adv -v v_adv,tuva_adv -v u_nudging,ua_nudging -h -v v_nudging,va_nudging -v w,wa -v zorog,orog -v height,zh \
-v sfc_sens_flx,hfss -v sfc_lat_flx,hfls \
${filename} -O ${filename} 


