FROM anapsix/alpine-java

#### Settings ####
ARG DRUID_VERSION=0.12.1
ARG TRANQUILITY_VERSION=0.8.2
ENV DRUID_HOME /opt/druid
ENV DRUID_MAVEN_REPO https://metamx.artifactoryonline.com/metamx/libs-releases
ENV PROMETHEUS_JAVAAGENT_VERSION=0.9

# Prerequisites
RUN apk add --update coreutils wget \
        && rm -f /var/cache/apk/*

###### Druid install BEGIN ######

RUN wget -q -O - http://static.druid.io/artifacts/releases/druid-$DRUID_VERSION-bin.tar.gz | tar -xzf - -C /opt \
 && ln -s /opt/druid-$DRUID_VERSION $DRUID_HOME \
 && mkdir $DRUID_HOME/prometheus \
 && wget -q -O $DRUID_HOME/prometheus/jmx_prometheus_javaagent-$PROMETHEUS_JAVAAGENT_VERSION.jar http://central.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$PROMETHEUS_JAVAAGENT_VERSION/jmx_prometheus_javaagent-$PROMETHEUS_JAVAAGENT_VERSION.jar \
 && rm -rf $DRUID_HOME/conf/

# Install extension libraries
RUN java -cp "$DRUID_HOME/lib/*" \
         -Ddruid.extensions.directory="$DRUID_HOME/extensions/" \
         -Ddruid.extensions.hadoopDependenciesDir="$DRUID_HOME/hadoop-dependencies/" \
         io.druid.cli.Main tools pull-deps \
         -c io.druid.extensions:mysql-metadata-storage:$DRUID_VERSION \
         # Installing contrib extensions
         -c io.druid.extensions.contrib:ambari-metrics-emitter:$DRUID_VERSION \
         -c io.druid.extensions.contrib:druid-azure-extensions:$DRUID_VERSION \
         -c io.druid.extensions.contrib:druid-cassandra-storage:$DRUID_VERSION \
         -c io.druid.extensions.contrib:druid-cloudfiles-extensions:$DRUID_VERSION \
         -c io.druid.extensions.contrib:druid-distinctcount:$DRUID_VERSION \
         # -c io.druid.extensions.contrib:druid-kafka-eight-simpleConsumer:$DRUID_VERSION \
         -c io.druid.extensions.contrib:druid-orc-extensions:$DRUID_VERSION \
         -c io.druid.extensions.contrib:druid-parquet-extensions:$DRUID_VERSION \
         -c io.druid.extensions.contrib:druid-rabbitmq:$DRUID_VERSION \
         -c io.druid.extensions.contrib:druid-redis-cache:$DRUID_VERSION \
         -c io.druid.extensions.contrib:druid-rocketmq:$DRUID_VERSION \
         -c io.druid.extensions.contrib:druid-time-min-max:$DRUID_VERSION \
         -c io.druid.extensions.contrib:druid-google-extensions:$DRUID_VERSION \
         -c io.druid.extensions.contrib:sqlserver-metadata-storage:$DRUID_VERSION \
         -c io.druid.extensions.contrib:graphite-emitter:$DRUID_VERSION \
         -c io.druid.extensions.contrib:statsd-emitter:$DRUID_VERSION \
         -c io.druid.extensions.contrib:kafka-emitter:$DRUID_VERSION \
         -c io.druid.extensions.contrib:druid-thrift-extensions:$DRUID_VERSION \
 # Moving mysql connector to /lib, so can it be reused by other parts of druid
 && mv $DRUID_HOME/extensions/mysql-metadata-storage/mysql-connector-java-*.jar $DRUID_HOME/lib \
 # Cleaning up
 && rm -rfv ~/.m2

# Put configuration files
#ADD conf $DRUID_HOME/conf/
ADD extras/prometheus_javaagent.yaml $DRUID_HOME/conf/

######## Final phase
WORKDIR $DRUID_HOME
ADD bin/entry-alt.sh $DRUID_HOME/bin/entry.sh
ENTRYPOINT /bin/bash bin/entry.sh

