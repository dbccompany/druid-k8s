#!/bin/bash -eu

# Ugly fix for zookeeper service discovery in k8s
if [ -n "${MY_POD_IP}" ]; then
  sed -i -e "1i \druid.host=${MY_POD_IP}" conf/_common/common.runtime.properties
fi

exec java `cat conf/${DRUID_ROLE}/jvm.config | xargs` -cp conf/_common:conf/${DRUID_ROLE}:lib/* io.druid.cli.Main server ${DRUID_ROLE}
