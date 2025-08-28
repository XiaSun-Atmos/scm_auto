#!/bin/bash -x
###############################################################
## Abstract:
## 1.Split ICON IC to each grid points and convert to DEPHY format
## 2. Run scm at each grid point in parallel
## 3. Add lat and lon dimension to CCPP SCM output and move to &
## another directory for future concatenate
## CDATE  : current date (YYYYMMDDHH)
## ICON_IC : /full/path/to/ICON/IC
## COMBINE_IC : /full/path/to/combined/IC
## cyc    : current cycle (HH)
## SCRIPTS: /full/path/to/job/scripts
## author: Xia Sun, CIRES at CU Boulder/NOAA Global Systems Laboratory (Xia.Sun@colorado.edu)
###############################################################

export PATH="/To/Your/Python/DIR"
which python
# Adding the local libs, so SCM won't touch /contrib for libraries
export LD_LIBRARY_PATH=/usr/lib64:/Your/Local/SCM/Lib:$LD_LIBRARY_PATH

yyyy=$(echo $CDATE | cut -c1-4)
mm=$(echo $CDATE | cut -c5-6)
dd=$(echo $CDATE | cut -c7-8)
cyc=${cyc:-$(echo $CDATE | cut -c9-10)}

yyyy3=$(echo $CDATE_3 | cut -c1-4)
mm3=$(echo $CDATE_3 | cut -c5-6)
dd3=$(echo $CDATE_3 | cut -c7-8)
cyc3=$(echo $CDATE_3 | cut -c9-10)

yyyy6=$(echo $CDATE_6 | cut -c1-4)
mm6=$(echo $CDATE_6 | cut -c5-6)
dd6=$(echo $CDATE_6 | cut -c7-8)
cyc6=$(echo $CDATE_6 | cut -c9-10)

yyyy9=$(echo $CDATE_9 | cut -c1-4)
mm9=$(echo $CDATE_9 | cut -c5-6)
dd9=$(echo $CDATE_9 | cut -c7-8)
cyc9=$(echo $CDATE_9 | cut -c9-10)

export yyyy
export mm
export dd
export cyc
if [ ! -d "${SCRATCH_DIR}/ccpp-scm-$yyyy$mm$dd$cyc" ]; then
    # Directory doesn't exist - do something
    cp -r ${SCM_DIR} ${SCRATCH_DIR}/ccpp-scm-$yyyy$mm$dd$cyc
    echo "Created directory"
else
    cp -r ${SCM_DIR}/scm/bin/scm ${SCRATCH_DIR}/ccpp-scm-$yyyy$mm$dd$cyc/scm/bin/
fi



cp -r ${SCRIPTS}/run_scm_paral_workflow.py ${SCRATCH_DIR}/ccpp-scm-$yyyy$mm$dd$cyc/scm/src/
cd ${SCRATCH_DIR}/ccpp-scm-$yyyy$mm$dd$cyc/scm/bin
ln -s ${SCRATCH_DIR}/ccpp-scm-$yyyy$mm$dd$cyc/scm/src/run_scm_paral_workflow.py .
./run_scm_paral_workflow.py -j 40

