# mysql backup to s3

### Binary

	docker run --rm \
	-e AWS_ACCESS_KEY=mykey \
	-e AWS_SECRET_KEY=mysecret \
	-e S3_BUCKET=mybucket \
	-e S3_PATH=backups/ \
	-e MYSQL_PORT=3306 \
	-e MYSQL_HOST=mysql \
	-e MYSQL_USER=user \
	-e MYSQL_PASS=pass \
	vixns/mysql-s3backup

### Mysqldump

	docker run --rm \
	-e AWS_ACCESS_KEY=mykey \
	-e AWS_SECRET_KEY=mysecret \
	-e S3_BUCKET=mybucket \
	-e S3_PATH=dumps/ \
	-e MYSQL_PORT=3306 \
	-e MYSQL_HOST=mysql \
	-e MYSQL_USER=user \
	-e MYSQL_PASS=pass \
	vixns/mysql-s3backup /dump.sh
