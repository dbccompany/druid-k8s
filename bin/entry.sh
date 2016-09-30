#!/bin/bash -eu

## Initializtion script for druid nodes

DRUID_ROOT=/opt/druid

# Allow to obtain programmatically HOSTNAME (for e.g. in AWS ECS)
if [[ ! -z ${HOSTNAME_COMMAND:-} ]]; then
  DRUID_HOST=$(eval $HOSTNAME_COMMAND)
fi

# Common settings
sed -i \
  -e "s;__ZK_HOST__;${ZK_HOST};" \
  -e "s;__ZK_PORT__;${ZK_PORT:-'2180'};" \
  -e "s;__MYSQL_HOST__;${MYSQL_HOST:-''};" \
  -e "s;__MYSQL_PORT__;${MYSQL_PORT:-''};" \
  -e "s;__MYSQL_DB__;${MYSQL_DB:-''};" \
  -e "s;__MYSQL_USER__;${MYSQL_USER:-''};" \
  -e "s;__MYSQL_PASS__;${MYSQL_PASS:-''};" \
  -e "s;__AWS_ACCESS_KEY__;${AWS_ACCESS_KEY:-''};" \
  -e "s;__AWS_SECRET_KEY__;${AWS_SECRET_KEY:-''};" \
  -e "s;__DRUID_HOST__;${DRUID_HOST:-''};" \
  -e "s;__DRUID_PORT__;${DRUID_PORT:-''};" \
  -e "s;__GROUPBY_MAXINTERMEDIATEROWS__;${GROUPBY_MAXINTERMEDIATEROWS:-50000};" \
  -e "s;__GROUPBY_MAXRESULTS__;${GROUPBY_MAXRESULTS:-500000};" \
  $DRUID_ROOT/conf/_common/common.runtime.properties

# Specific settings
case $NODE_TYPE in
  broker)
    sed -i \
      -e "s;__PROCESSING_BUFFER_SIZEBYTES__;${PROCESSING_BUFFER_SIZEBYTES:-2147483647};" \
      -e "s;__PROCESSING_NUMTHREADS__;${PROCESSING_NUMTHREADS:-2};" \
      $DRUID_ROOT/conf/$NODE_TYPE/runtime.properties
  ;;

  coordinator)
#    sed -i \
#      
#      $DRUID_ROOT/conf/$NODE_TYPE/runtime.properties
    echo "No settings specific to coordinator so far"
  ;;

  historical)
    sed -i \
      -e "s;__PROCESSING_BUFFER_SIZEBYTES__;${PROCESSING_BUFFER_SIZEBYTES:-1073741824};" \
      -e "s;__PROCESSING_NUMTHREADS__;${PROCESSING_NUMTHREADS:-2};" \
      -e "s;__SEGMENT_CACHE_LOCATION__;${SEGMENT_CACHE_LOCATION:-/mnt/persistent/zk_druid};" \
      -e "s;__SEGMENT_CACHE_MAXSIZE__;${SEGMENT_CACHE_MAXSIZE:-7000000000};" \
      $DRUID_ROOT/conf/$NODE_TYPE/runtime.properties
  ;;

  middleManager)
    sed -i \
      -e "s;__S3_BUCKET__;${S3_BUCKET};" \
      -e "s;__PROCESSING_BUFFER_SIZEBYTES__;${PROCESSING_BUFFER_SIZEBYTES:-536870912};" \
      -e "s;__PROCESSING_NUMTHREADS__;${PROCESSING_NUMTHREADS:-2};" \
      -e "s;__SEGMENT_CACHE_LOCATION__;${SEGMENT_CACHE_LOCATION:-/mnt/persistent/zk_druid};" \
      -e "s;__SEGMENT_CACHE_MAXSIZE__;${SEGMENT_CACHE_MAXSIZE:-0};" \
      $DRUID_ROOT/conf/$NODE_TYPE/runtime.properties
  ;;

  overlord)
    sed -i \
      -e "s;__S3_BUCKET__;${S3_BUCKET};" \
      $DRUID_ROOT/conf/$NODE_TYPE/runtime.properties
  ;;

  *)
    echo "$NODE_TYPE is not valid value for \$NODE_TYPE"
    echo "should be one of: broker coordinator historical middleManager overlord"
    exit 1
  ;;
esac

java $JAVA_PROPERTIES -cp $DRUID_ROOT/conf/_common:$DRUID_ROOT/conf/$NODE_TYPE:$DRUID_ROOT/lib/* io.druid.cli.Main server $NODE_TYPE
