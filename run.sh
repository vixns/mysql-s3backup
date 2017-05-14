#!/bin/bash

set -eo pipefail

DATESTAMP=$(date +"%Y_%V")
TIMESTAMP=$(date +"inc_%s")
week_minus2=$(date --date="2 weeks ago" +"%Y_%V")

TMP_PATH=/tmp/${DATESTAMP}/
BACKUP_PATH=/backups/${DATESTAMP}/
OLDBACKUP_PATH=/backups/${week_minus2}/

PERCONA_BACKUP_COMMAND=/usr/bin/innobackupex

cat > config.cnf <<EOF
[client]
user = ${MYSQL_USER}
password = ${MYSQL_PASS}
host = ${MYSQL_HOST}
port = ${MYSQL_PORT}
EOF


if [ -e "${BACKUP_PATH}latest" ]; then
	# incremental backup
	BACKUP_DIRNAME=${TIMESTAMP}
	${PERCONA_BACKUP_COMMAND} --defaults-extra-file=config.cnf --no-timestamp \
	--incremental --incremental-basedir ${BACKUP_PATH}latest --use-memory=640M \
	${TMP_PATH}${BACKUP_DIRNAME}
else
	# full backup
	BACKUP_DIRNAME=full
	${PERCONA_BACKUP_COMMAND}--defaults-extra-file=config.cnf --no-timestamp \
	--use-memory=640M ${TMP_PATH}${BACKUP_DIRNAME}
	rm -rf ${OLDBACKUP_PATH}${BACKUP_DIRNAME}
fi	

tar czf ${TMP_PATH}${BACKUP_DIRNAME}.tar.gz -C ${TMP_PATH} ${BACKUP_DIRNAME}
[ -z "${AWS_ACCESS_KEY}" ] || s3cmd --no-progress --access_key=${AWS_ACCESS_KEY} \
--secret_key=${AWS_SECRET_KEY} put -f ${TMP_PATH}${BACKUP_DIRNAME}.tar.gz \
s3://${S3_BUCKET}/${S3_PATH}${DATESTAMP}/

mkdir -p ${BACKUP_PATH}${BACKUP_DIRNAME}
mv ${TMP_PATH}${BACKUP_DIRNAME}/xtrabackup_* ${BACKUP_PATH}${BACKUP_DIRNAME}
cd ${BACKUP_PATH}
rm latest
ln -s ${BACKUP_DIRNAME} latest
