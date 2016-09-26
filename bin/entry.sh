#!/bin/bash -eu

## Initializtion script for druid nodes

DRUID_ROOT=/opt/druid

HOST_VARNAME=$(echo $NODE_TYPE | tr '[:lower:]' '[:upper:]')_HOST

# Autodetecting role's IP address
if [ -z ${!HOST_VARNAME+x}]; then
  if LOCAL_IPV4=$(wget --tries=3 --timeout=1 -q -O - http://169.254.169.254/1.0/meta-data/local-ipv4); then
    declare $(echo $NODE_TYPE | tr '[:lower:]' '[:upper:]')_HOST=$LOCAL_IPV4
#  else
#    declare $(echo $NODE_TYPE | tr '[:lower:]' '[:upper:]')_HOST=1.1.1.1
  fi
fi

CONFIG_FILES=$(find $DRUID_ROOT/conf -type f -name '*.properties')

for CONFIG_FILE in $CONFIG_FILES; do
  sed -i \
    -e "s;__S3_BUCKET__;${S3_BUCKET};" \
    -e "s;__ZK_HOST__;${ZK_HOST};" \
    -e "s;__ZK_PORT__;${ZK_PORT:-'2180'};" \
    -e "s;__MYSQL_HOST__;${MYSQL_HOST:-''};" \
    -e "s;__MYSQL_PORT__;${MYSQL_PORT:-''};" \
    -e "s;__MYSQL_DB__;${MYSQL_DB:-''};" \
    -e "s;__MYSQL_USER__;${MYSQL_USER:-''};" \
    -e "s;__MYSQL_PASS__;${MYSQL_PASS:-''};" \
    -e "s;__AWS_ACCESS_KEY__;${AWS_ACCESS_KEY:-''};" \
    -e "s;__AWS_SECRET_KEY__;${AWS_SECRET_KEY:-''};" \
    -e "s;__${HOST_VARNAME}__;${!HOST_VARNAME};" \
    -e "s;__BROKER_PORT__;${BROKER_PORT:-''};" \
    -e "s;__COORDINATOR_PORT__;${COORDINATOR_PORT:-''};" \
    -e "s;__HISTORICAL_PORT__;${HISTORICAL_PORT:-''};" \
    -e "s;__MIDDLEMANAGER_PORT__;${MIDDLEMANAGER_PORT:-''};" \
    -e "s;__OVERLORD_PORT__;${OVERLORD_PORT:-''};" \
    -e "s;__GROUPBY_MAXINTERMEDIATEROWS__;${GROUPBY_MAXINTERMEDIATEROWS:-50000};" \
    -e "s;__GROUPBY_MAXRESULTS__;${GROUPBY_MAXRESULTS:-500000};" \
    -e "s;__PROCESSING_BUFFER_SIZEBYTES__;${PROCESSING_BUFFER_SIZEBYTES:-1073741824};" \
    -e "s;__PROCESSING_NUMTHREADS__;${PROCESSING_NUMTHREADS:-2};" \
    $CONFIG_FILE
done

java $JAVA_PROPERTIES -cp $DRUID_ROOT/conf/_common:$DRUID_ROOT/conf/$NODE_TYPE:$DRUID_ROOT/lib/* io.druid.cli.Main server $NODE_TYPE
