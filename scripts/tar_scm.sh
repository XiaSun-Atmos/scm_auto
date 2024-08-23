#!/bin/bash -l
###############################################################
## Abstract:
## tar scm outputs using pigz
## CDATE  : current date (YYYYMMDDHH)
## ICON_IC : /full/path/to/ICON/IC
## COMBINE_IC : /full/path/to/combined/IC
## cyc    : current cycle (HH)
## SCRIPTS: /full/path/to/job/scripts
## PYSCRIPTS: /full/path/to/python/scripts
## CONCATE_OUTPUT: /full/path/to/concatenate/output
###############################################################

export PATH="/work/noaa/gmtb/xiasun/MU-MIP/tools/gnu_parallel/bin:$PATH"
export PATH="/work/noaa/gmtb/xiasun/MU-MIP/tools/pigz-2.8:$PATH"


yyyy=$(echo $CDATE | cut -c1-4)
mm=$(echo $CDATE | cut -c5-6)
dd=$(echo $CDATE | cut -c7-8)
cyc=${cyc:-$(echo $CDATE | cut -c9-10)}
suite1=SCM_GFS_v17_HR3
export suite1
# mkdir ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all
# export var
minsize=5000


yyyy=$(echo $CDATE | cut -c1-4)
mm=$(echo $CDATE | cut -c5-6)
dd=$(echo $CDATE | cut -c7-8)
cyc=${cyc:-$(echo $CDATE | cut -c9-10)}


yyyy3=$(echo $CDATE_3 | cut -c1-4)
mm3=$(echo $CDATE_3 | cut -c5-6)
dd3=$(echo $CDATE_3 | cut -c7-8)
cyc3=${cyc6:-$(echo $CDATE_3 | cut -c9-10)}


yyyy6=$(echo $CDATE_6 | cut -c1-4)
mm6=$(echo $CDATE_6 | cut -c5-6)
dd6=$(echo $CDATE_6 | cut -c7-8)
cyc6=${cyc6:-$(echo $CDATE_6 | cut -c9-10)}

cd ${SCM_RESULTS}

# tar all the scm output 
tar -cf - ${mm}_${dd}_${cyc}/* | pigz -p 16 > ${mm}_${dd}_${cyc}_scm.tar.gz

rm -rf ${SCM_RESULTS}/${mm}_${dd}_${cyc}/lat_*
rm -rf ${SPLIT_IC}/${mm}_${dd}_${cyc}
rm -rf ${STDOUT}/scm_auto/${mm}${dd}${cyc}*
mkdir ${SCM_RESULTS}/2016_${EXP}_scm
cd ${SCM_RESULTS}/2016_${EXP}_${CCPP_SUITE}

# rsync files at each time stamp for each var to the final dir 
# rsync -av --ignore-existing ${SCM_RESULTS}/${mm}_${dd}_${cyc}/output_all/ .
