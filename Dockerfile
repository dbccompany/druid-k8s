FROM anapsix/alpine-java

#### Settings ####
ARG DRUID_VERSION=0.15.1-incubating
ENV DRUID_HOME /opt/druid
ENV DRUID_MAVEN_REPO https://metamx.artifactoryonline.com/metamx/libs-releases
ENV PROMETHEUS_JAVAAGENT_VERSION=0.11.0
ENV AMAZON_KINESIS_CLIENT_LIBRARY=1.10.0

# Prerequisites
RUN apk add --update coreutils wget \
        && rm -f /var/cache/apk/*

###### Druid install BEGIN ######

RUN wget -q -O - https://www-us.apache.org/dist/incubator/druid/$DRUID_VERSION/apache-druid-$DRUID_VERSION-bin.tar.gz | tar -xzf - -C /opt \
 && ln -s /opt/apache-druid-$DRUID_VERSION $DRUID_HOME \
 && mkdir $DRUID_HOME/prometheus \
 && wget -q -O $DRUID_HOME/prometheus/jmx_prometheus_javaagent-$PROMETHEUS_JAVAAGENT_VERSION.jar http://central.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$PROMETHEUS_JAVAAGENT_VERSION/jmx_prometheus_javaagent-$PROMETHEUS_JAVAAGENT_VERSION.jar \
 && wget -q -O $DRUID_HOME/lib/mysql-connector-java-8.0.16.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.16/mysql-connector-java-8.0.16.jar \
 && rm -rf $DRUID_HOME/conf/

# Install extension libraries
RUN java -cp "$DRUID_HOME/lib/*" \
         -Ddruid.extensions.directory="$DRUID_HOME/extensions/" \
         -Ddruid.extensions.hadoopDependenciesDir="$DRUID_HOME/hadoop-dependencies/" \
         org.apache.druid.cli.Main tools pull-deps \
         # Installing contrib extensions
         -c org.apache.druid.extensions.contrib:ambari-metrics-emitter:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-azure-extensions:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-cassandra-storage:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-cloudfiles-extensions:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-distinctcount:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-kafka-eight-simple-consumer:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-opentsdb-emitter:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-rabbitmq:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-redis-cache:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-rocketmq:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-time-min-max:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-virtual-columns:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:sqlserver-metadata-storage:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:graphite-emitter:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:statsd-emitter:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:kafka-emitter:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-thrift-extensions:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:materialized-view-maintenance:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:materialized-view-selection:$DRUID_VERSION \
         -c org.apache.druid.extensions.contrib:druid-moving-average-query:$DRUID_VERSION \
    # Cleaning up
    && rm -rfv ~/.m2
    # Moving mysql connector to /lib, so can it be reused by other parts of druid
    #&& mv $DRUID_HOME/extensions/mysql-metadata-storage/mysql-connector-java-*.jar $DRUID_HOME/lib

# Adding Kinesis Client Library for kinesis indexer
RUN wget -q -O $DRUID_HOME/extensions/druid-kinesis-indexing-service/amazon-kinesis-client-$AMAZON_KINESIS_CLIENT_LIBRARY.jar https://repo1.maven.org/maven2/com/amazonaws/amazon-kinesis-client/$AMAZON_KINESIS_CLIENT_LIBRARY/amazon-kinesis-client-$AMAZON_KINESIS_CLIENT_LIBRARY.jar

# Put configuration files
#ADD conf $DRUID_HOME/conf/
ADD extras/prometheus_javaagent.yaml $DRUID_HOME/conf/

######## Final phase
WORKDIR $DRUID_HOME
ADD bin/entry-alt.sh $DRUID_HOME/bin/entry.sh
ENTRYPOINT /bin/bash bin/entry.sh

# Temporary testing statsd dimensions mapping patch
COPY build/extensions-contrib/statsd-emitter/src/main/resources/defaultMetricDimensions.json /dimensions.json
