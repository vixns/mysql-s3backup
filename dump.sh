#!/bin/bash

set -eo pipefail

filename=mysqldump-$(date -I'minutes').sql.gz

cat > config.cnf <<EOF
[client]
user = ${MYSQL_USER}
password = "${MYSQL_PASS}"
host = ${MYSQL_HOST}
port = ${MYSQL_PORT}
EOF

chmod 0600 config.cnf

mkdir -p /backups

if [ "$CREATE_ONE_FILE_PER_DB" = "true" ]; then
  mysql --defaults-extra-file=config.cnf --skip-column-names -e 'show databases' \
    | while read dbname; do
      [ "$dbname" != "performance_schema" ] || continue;
      [ "$dbname" != "information_schema" ] || continue;
      echo "Dumping $dbname ..."
      mysqldump --defaults-extra-file=config.cnf "$dbname" -R --extended-insert --quick \
      --single-transaction --max_allowed_packet=500M -f | gzip -9 -c > /backups/${dbname}-${filename}
    if [ -n "${AWS_ACCESS_KEY}" ]; then
      echo "send $dbname to s3"
      s3cmd --no-progress --access_key=${AWS_ACCESS_KEY} --secret_key=${AWS_SECRET_KEY} \
      put -f /backups/${dbname}-${filename} s3://${S3_BUCKET}/${S3_PATH}dumps/
    fi
  done;
else
  echo Dumping all databases ...
  mysqldump --defaults-extra-file=config.cnf -R --all-databases --extended-insert --quick \
  --single-transaction --max_allowed_packet=500M -f | gzip -9 -c > /backups/${filename}
  if [ -n "${AWS_ACCESS_KEY}" ]; then
    echo "send to s3"
    s3cmd --no-progress --access_key=${AWS_ACCESS_KEY} --secret_key=${AWS_SECRET_KEY} \
    put -f /backups/${filename} s3://${S3_BUCKET}/${S3_PATH}dumps/
  fi
fi
