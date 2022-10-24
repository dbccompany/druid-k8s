FROM openjdk:8u312-jre-buster

#### Settings ####
ARG DRUID_VERSION=0.22.1
ENV DRUID_HOME=/opt/druid \
    DRUID_MAVEN_REPO=https://metamx.artifactoryonline.com/metamx/libs-releases \
    AMAZON_KINESIS_CLIENT_LIBRARY=1.11.2 \
    MYSQL_CONNECTOR_VERSION=5.1.48 \
    PROMETHEUS_JMX_JAVAAGENT=0.12.0

# Prerequisites
RUN apt-get update \
 && apt-get -y install wget \
 && apt-get clean

###### Druid install BEGIN ######

RUN wget -q -O - https://downloads.apache.org/druid/$DRUID_VERSION/apache-druid-$DRUID_VERSION-bin.tar.gz | tar -xzf - -C /opt \
 && ln -s /opt/apache-druid-$DRUID_VERSION $DRUID_HOME \
 && mkdir $DRUID_HOME/prometheus \
 && wget -q -O $DRUID_HOME/lib/mysql-connector-java-$MYSQL_CONNECTOR_VERSION.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/$MYSQL_CONNECTOR_VERSION/mysql-connector-java-$MYSQL_CONNECTOR_VERSION.jar \
# Adding Kinesis Client Library for kinesis indexer
  && wget -q -O $DRUID_HOME/extensions/druid-kinesis-indexing-service/amazon-kinesis-client-$AMAZON_KINESIS_CLIENT_LIBRARY.jar https://repo1.maven.org/maven2/com/amazonaws/amazon-kinesis-client/$AMAZON_KINESIS_CLIENT_LIBRARY/amazon-kinesis-client-$AMAZON_KINESIS_CLIENT_LIBRARY.jar \
 && rm -rf $DRUID_HOME/conf/ \
 && wget -q  https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$PROMETHEUS_JMX_JAVAAGENT/jmx_prometheus_javaagent-$PROMETHEUS_JMX_JAVAAGENT.jar -O  $DRUID_HOME/lib/jmx_prometheus_javaagent-$PROMETHEUS_JMX_JAVAAGENT.jar

# Install extension libraries
RUN java -cp "$DRUID_HOME/lib/*" \
         -Ddruid.extensions.directory="$DRUID_HOME/extensions/" \
         -Ddruid.extensions.hadoopDependenciesDir="$DRUID_HOME/hadoop-dependencies/" \
         org.apache.druid.cli.Main tools pull-deps \
         # Installing contrib extensions
         -c org.apache.druid.extensions.contrib:ambari-metrics-emitter:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-cassandra-storage:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-cloudfiles-extensions:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-distinctcount:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-redis-cache:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-time-min-max:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:sqlserver-metadata-storage:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:graphite-emitter:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:statsd-emitter:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:kafka-emitter:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-thrift-extensions:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-opentsdb-emitter:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:materialized-view-selection:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:materialized-view-maintenance:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-moving-average-query:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-influxdb-emitter:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-momentsketch:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-tdigestsketch:$DRUID_VERSION \
    # Cleaning up
    && rm -rfv ~/.m2
    # Linking mysql connector to mysql-metadata-storage extension directory
    #&& ln -s $DRUID_HOME/lib/mysql-connector-java-$MYSQL_CONNECTOR_VERSION.jar \
    #         $DRUID_HOME/extensions/mysql-metadata-storage/mysql-connector-java-$MYSQL_CONNECTOR_VERSION.jar \
    #&& ln -s $DRUID_HOME/lib/mysql-connector-java-$MYSQL_CONNECTOR_VERSION.jar \
    #         $DRUID_HOME/extensions/druid-lookups-cached-global/mysql-connector-java-$MYSQL_CONNECTOR_VERSION.jar

######## Final phase
WORKDIR $DRUID_HOME
ADD bin/entry-alt.sh $DRUID_HOME/bin/entry.sh
ADD bin/config.yaml /etc/config.yaml
ENTRYPOINT /bin/bash bin/entry.sh
