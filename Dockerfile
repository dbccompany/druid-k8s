FROM ubuntu:16.04

#### Settings ####
ARG DRUID_VERSION=0.12.0
ENV DRUID_HOME /opt/druid
ENV DRUID_MAVEN_REPO https://metamx.artifactoryonline.com/metamx/libs-releases
ENV PROMETHEUS_JAVAAGENT_VERSION=0.9

######### Oracle Java magic BEGIN #########
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" > /etc/apt/sources.list.d/webupd8team-java.list
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886 \
 && apt-get update \
 && apt-get install -y oracle-java8-installer \
 && rm -rf /var/cache/oracle-jdk8-installer \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /var/cache/debconf

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
########## Oracle Java magic END ##########


###### Druid install BEGIN ######

RUN wget -q -O - http://static.druid.io/artifacts/releases/druid-$DRUID_VERSION-bin.tar.gz | tar -xzf - -C /opt \
 && ln -s /opt/druid-$DRUID_VERSION $DRUID_HOME \
 && mkdir $DRUID_HOME/prometheus \
 && wget -q -O $DRUID_HOME/prometheus/jmx_prometheus_javaagent-$PROMETHEUS_JAVAAGENT_VERSION.jar http://central.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$PROMETHEUS_JAVAAGENT_VERSION/jmx_prometheus_javaagent-$PROMETHEUS_JAVAAGENT_VERSION.jar \
 && rm -rf $DRUID_HOME/conf/ \

# Install extension libraries
 && java -cp "$DRUID_HOME/lib/*" \
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
#         -c io.druid.extensions.contrib:druid-kafka-eight-simpleConsumer:$DRUID_VERSION \
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

