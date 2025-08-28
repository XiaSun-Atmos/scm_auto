#!/bin/bash -l
###############################################################
## Abstract:
## tar scm outputs 
## CDATE  : current date (YYYYMMDDHH)
## ICON_IC : /full/path/to/ICON/IC
## COMBINE_IC : /full/path/to/combined/IC
## cyc    : current cycle (HH)
## SCRIPTS: /full/path/to/job/scripts
## PYSCRIPTS: /full/path/to/python/scripts
## CONCATE_OUTPUT: /full/path/to/concatenate/output
###############################################################


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

cd ${SCM_RESULTS}/${CCPP_SUITE}/${mm}_${dd}_${cyc}/
cp -r ${SCRIPTS}/tar.sh .
sh tar.sh >& tar.log