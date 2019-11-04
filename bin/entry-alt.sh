#!/bin/bash -eu

# Next ugly fix requires workaround since k8s-1.9.6
# see details in https://github.com/kubernetes/kubernetes/issues/62099
# Helm package assumed to mount files from configmap to somewhere else
# and we copy it over then
if [ -n "${MY_POD_IP}" ]; then
  cp -a conf-k8s/* conf/
fi

# Ugly fix for zookeeper service discovery in k8s
if [ -n "${MY_POD_IP}" ]; then
  sed -i -e "1i \druid.host=${MY_POD_IP}" conf/_common/common.runtime.properties
fi

#exec java `cat conf/${DRUID_ROLE}/jvm.config | xargs` -cp conf/_common:conf/${DRUID_ROLE}:lib/* org.apache.druid.cli.Main server ${DRUID_ROLE}
exec java $JAVA_OPTS  -cp conf/_common:conf/${DRUID_ROLE}:lib/* org.apache.druid.cli.Main server ${DRUID_ROLE}
