#!/bin/bash

set -eo pipefail

if [ $# -lt 2 ] ; then
  echo "Usage: $0 timestamp /restore/dir"
  exit 1
fi

TS=$1
DATESTAMP=$(date +"%Y_%V" -d $TS)
TIMESTAMP=$(date +"%s" -d $TS)
S3CMD="s3cmd --no-progress --access_key=${AWS_ACCESS_KEY} --secret_key=${AWS_SECRET_KEY}"

RESTOREDIR=$2
TMP_PATH="/tmp/"
FULL_PATH="${TMP_PATH}full"
INCRS_PATH="${TMP_PATH}incrs/"


[ -d "$RESTOREDIR" ] || mkdir -p $RESTOREDIR
[ -d "${INCRS_PATH}"  ] || mkdir -p ${INCRS_PATH}

#get increments
for increment in $($S3CMD ls s3://${S3_BUCKET}${S3_PATH}/${DATESTAMP}/inc_* | awk '{print $NF}' | sort)
do
	incts=$(echo $increment | awk -F'_' '{print $NF}' | awk -F'.' '{print $1}')
	[ $incts -gt $TIMESTAMP ] || continue
	lastinc=$incts

	incfilename="${INCRS_PATH}${incts}.tar.gz"
	[ -e "${incfilename}" ] || $S3CMD get ${increment} ${incfilename}		
done

#get the full backup
[ -e "${FULL_PATH}.tar.gz" ] || $S3CMD get s3://${S3_BUCKET}/${S3_PATH}${DATESTAMP}/full.tar.gz ${FULL_PATH}.tar.gz

#decompress all
cd ${TMP_PATH}
tar zxf full.tar.gz

cd ${TMP_PATH}inc
for z in $(ls "*tar.gz")
do
	tar zxf $z
done

# prepare base backup
xtrabackup --prepare --apply-log-only --target-dir=${FULL_PATH}

 # Apply incrementals to base backup
    for i in `find ${INCRS_PATH} -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -n`; do
      echo "Applying $i to full ..."
      if [ $lastinc = $i ]; then
        break # break. we are restoring up to this incremental.
      fi
      xtrabackup --prepare --apply-log-only --target-dir=${FULL_PATH} --incremental-dir=${INCRS_PATH}$i
    done

if [ -z "$lastinc" ]
then
	#no increments, redo logs on base backup
	xtrabackup --prepare --target-dir=${FULL_PATH}
else
	#Apply last increment
	xtrabackup --prepare --target-dir=${FULL_PATH} --incremental-dir=${INCRS_PATH}$lastinc
fi
#move to restore dir
rsync -avrP ${FULL_PATH}/ ${RESTOREDIR}/

