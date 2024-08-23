# purpose: convert UFC CG forcing to dephy v1 to drive CCPP SCM, MUMIP project, 2024
# contact: Kathryn Newman, knewman@ucar.edu 
#          Xia Sun, xia.sun@noaa.gov
#          Will Mayfield, wmayfield@ucar.edu 


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
ncrename -h -v u_t,u -v v_t,v -v height_t,height -v ps_t,ps -v pressure_t,pressure -v temp_t,temp init_time_${filename} -O init_time_${filename}
ncrename -h -v qi_t,qi -v ql_t,ql -v qt_t,qt -v qv_t,qv -v theta_t,theta -v thetal_t,thetal init_time_${filename} -O init_time_${filename}

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

ncrename -h -v ps_t,ps_forc -v height_t,height_forc -v pressure_t,pressure_forc ${filename} -O ${filename}
ncrename -h -v u_t,u_nudging -v v_t,v_nudging -v theta_t,theta_nudging -v thetal_t,thetal_nudging -v temp_t,temp_forc ${filename} -O ${filename}
ncrename -h -v qi_t,qi_nudging -v ql_t,ql_nudging -v qt_t,qt_nudging -v qv_t,qv_nudging ${filename} -O ${filename}
ncrename -h -v rl_t,rl_nudging -v ri_t,ri_nudging -v rv_t,rv_nudging -v rt_t,rt_nudging ${filename} -O ${filename}
#add mixing ratios
#previously setting r=q. Instead add computation below
#ncap2 -h -s'rl_nudging=ql_nudging;rv_nudging=qv_nudging;ri_nudging=qi_nudging;rt_nudging=qt_nudging;' ${filename} -O ${filename}
##ncrename -h -v ri_t,ri_nudging -v rl_t,rl_nudging -v rt_t,rt_nudging -v rv_t,rv_nudging ${filename} -O ${filename}
# ncap2 -h -s'rl_nudging=ql_nudging/(1.0-ql_nudging);' ${filename} -O ${filename}
# ncap2 -h -s'ri_nudging=qi_nudging/(1.0-qi_nudging);' ${filename} -O ${filename}
# ncap2 -h -s'rv_nudging=qv_nudging/(1.0-qv_nudging);' ${filename} -O ${filename}
# ncap2 -h -s'rt_nudging=qt_nudging/(1.0-qt_nudging);' ${filename} -O ${filename}

#ncap2 -h -s'rv_adv=qv_adv;rt_adv=qt_adv;' ${filename} -O ${filename}

# ncap2 -h -s'rv_adv=qv_adv/(1.0-qv_adv);' ${filename} -O ${filename}
# ncap2 -h -s'rt_adv=qt_adv/(1.0-qt_adv);' ${filename} -O ${filename}
ncap2 -h -s'rv_adv=rv_adv;' ${filename} -O ${filename} # we may not need this, Xia Mar 2024
ncap2 -h -s'rt_adv=rt_adv;' ${filename} -O ${filename} # we may not need this, Xia Mar 2024
#concatenate initial vars file to create final DEPHY v0 file
ncks -h init_vars_${filename} -A ${filename}

#ncap2 -h -s'thetal=theta;thetal_adv=theta_adv;' ${filename} -O ${filename}
ncap2 -h -s'thetal_adv=thetal_adv;' ${filename} -O ${filename} # we may not need this, Xia Mar 2024
# ncap2 -h -s'thetal=theta-(theta/temp)*('${l_v}'/'${c_pd}')*rt;' ${filename} -O ${filename}

###   global attributes   ###
z0=`ncdump -v z0 ${filename} | tail -n 2 | head -n 1 | cut -d ';' -f 1`
zorog=`ncdump -v zorog ${filename} | tail -n 2 | head -n 1 | cut -d ';' -f 1`
zorog=$(($zorog))
z0=`echo ${z0} | xargs`


echo "start ncatted process"
ncatted -h -a surfaceType,global,c,c,ocean ${filename} -O ${filename}
ncatted -h -a surfaceForcing,global,m,c,surfaceFlux ${filename} -O ${filename}
ncatted -h -a surfaceForcingWind,global,m,c,z0 ${filename} -O ${filename}
ncatted -h -a zorog,global,c,f,${zorog} ${filename} -O ${filename}
ncatted -h -a z0,global,c,f,${z0} ${filename} -O ${filename}
ncatted -h -a nudging_temp,global,m,i,0 ${filename} -O ${filename}
ncatted -h -a forc_w,global,m,i,0 ${filename} -O ${filename}

#changes for startDate and endDate
yr=${startdate:0:4}
mo=${startdate:4:2}
dy=${startdate:6:2}
hr=${startdate:8:2}
min=${startdate:10:2}
sec=${startdate:12:2}
echo "$sec"
datestring=${yr}'-'${mo}'-'${dy}' '${hr}':'${min}':'${sec}


ncap2 -h -s't0=0;' ${filename} -O ${filename}
ncatted -h -O -a units,t0,o,c,"seconds since ${datestring}" ${filename}
ncatted -h -a startDate,global,m,c,${startdate} ${filename} -O ${filename} 
ncatted -h -a endDate,global,m,c,${enddate} ${filename} -O ${filename}
echo "start nuding rename"
ncatted -h -a nudging_v,global,m,i,0 ${filename} -O ${filename}
ncatted -h -a nudging_u,global,m,i,0 ${filename} -O ${filename}
ncatted -h -a nudging_rt,global,m,i,0 ${filename} -O ${filename}
ncatted -h -a nudging_rv,global,m,i,0 ${filename} -O ${filename}
ncatted -h -a nudging_qt,global,m,i,0 ${filename} -O ${filename}
ncatted -h -a nudging_qv,global,m,i,0 ${filename} -O ${filename}
ncatted -h -a nudging_theta,global,m,i,0 ${filename} -O ${filename}
ncatted -h -a nudging_thetal,global,m,i,0 ${filename} -O ${filename}
ncatted -h -a nudging_temp,global,m,i,0 ${filename} -O ${filename}
ncatted -h -a forc_w,global,m,i,1 ${filename} -O ${filename}
ncatted -h -a forc_geo,global,m,i,1 ${filename} -O ${filename}

#change time 
ncap2 -h -s 'time(:)={0,10800,21600,32400}' ${filename} -O ${filename} 
ncatted -h -O -a units,time,o,c,"seconds since ${datestring}" ${filename}
# add tke and set to 0
ncap2 -h -s 'tke[t0, lev, lat, lon]=0.' ${filename} -O ${filename} 

#flip vertical dimension of all variables
ncpdq -h -a -lev ${filename} -O ${filename}
rm -f init_vars_${filename}
rm -f init_time_${filename}


