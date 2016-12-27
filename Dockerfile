FROM vixns/base

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8507EFA5 && \
  echo "deb http://repo.percona.com/apt `lsb_release -cs` main" > /etc/apt/sources.list.d/percona.list && \
  apt-get update && apt-get -y dist-upgrade && \
  apt-get install --no-install-recommends --auto-remove -y percona-xtrabackup s3cmd rsync percona-server-client && \
  rm -rf /var/lib/apt/lists/* && \
  sed -i 's/^\(bind-address\s.*\) /# \1/' /etc/mysql/my.cnf && \
  sed -i 's/^\(log_error\s.*\)/# \1/' /etc/mysql/my.cnf

ADD run.sh /run.sh
ADD dump.sh /dump.sh
ADD restore.sh /restore.sh
CMD ["/run.sh"]
