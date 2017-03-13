#!/bin/bash

set -eo pipefail

filename=mysqldump-$(date -I'minutes').sql.gz

if [ "$CREATE_ONE_FILE_PER_DB" = "true" ]; then
  echo Dump per database enable;
  mysql --skip-column-names -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASS} -e 'show databases' \
    | while read dbname; do echo Dumping $dbname ... && mysqldump -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASS} "$dbname" -R --extended-insert --quick --single-transaction --max_allowed_packet=500M -f \
    | gzip -9 -c > /backups/${dbname}-${filename}.sql.gz
    s3cmd --no-progress --access_key=${AWS_ACCESS_KEY} --secret_key=${AWS_SECRET_KEY} put -f /backups/${dbname}-${filename}.sql.gz s3://${S3_BUCKET}/${S3_PATH}dumps/
  done;
else
  mysqldump -h ${MYSQL_HOST} -p{MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASS} -R --all-databases --extended-insert --quick --single-transaction --max_allowed_packet=500M -f | gzip -9 -c > /backups/${filename}
  [ -z "${AWS_ACCESS_KEY}" ] || s3cmd --no-progress --access_key=${AWS_ACCESS_KEY} --secret_key=${AWS_SECRET_KEY} put -f /backups/${filename} s3://${S3_BUCKET}/${S3_PATH}dumps/
fi
