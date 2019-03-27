FROM ubuntu

# Install Java.
RUN apt update && apt -y install software-properties-common && \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get install -y oracle-java8-installer


# Define working directory.
WORKDIR /data

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

RUN apt -y install maven

WORKDIR /tmp/build

COPY . .

RUN mvn clean install -Pdist -DskipTests

RUN mvn install -DskipTests

ARG DRUID_VERSION=0.14.1-incubating-SNAPSHOT

RUN tar -xvf distribution/target/apache-druid-$DRUID_VERSION-bin.tar.gz \
 && cd apache-druid-$DRUID_VERSION \
 && java -cp "lib/*" \
      -Ddruid.extensions.directory="extensions/" \
      -Ddruid.extensions.hadoopDependenciesDir="hadoop-dependencies/" \
      org.apache.druid.cli.Main tools pull-deps \
      # Installing contrib extensions
      -c org.apache.druid.extensions.contrib:ambari-metrics-emitter \
      -c org.apache.druid.extensions.contrib:druid-cassandra-storage \
      -c org.apache.druid.extensions.contrib:druid-cloudfiles-extensions \
      -c org.apache.druid.extensions.contrib:druid-distinctcount \
      -c org.apache.druid.extensions.contrib:druid-rocketmq \
      -c org.apache.druid.extensions.contrib:druid-google-extensions \
      -c org.apache.druid.extensions.contrib:graphite-emitter \
      -c org.apache.druid.extensions.contrib:druid-influx-extensions \
      -c org.apache.druid.extensions.contrib:kafka-emitter \
      -c org.apache.druid.extensions.contrib:materialized-view-maintenance \
      -c org.apache.druid.extensions.contrib:materialized-view-selection \
      -c org.apache.druid.extensions.contrib:druid-opentsdb-emitter \
      -c org.apache.druid.extensions.contrib:druid-orc-extensions \
      -c org.apache.druid.extensions.contrib:druid-rabbitmq \
      -c org.apache.druid.extensions.contrib:druid-redis-cache \
      -c org.apache.druid.extensions.contrib:sqlserver-metadata-storage \
      -c org.apache.druid.extensions.contrib:statsd-emitter \
      -c org.apache.druid.extensions.contrib:druid-thrift-extensions \
      -c org.apache.druid.extensions.contrib:druid-time-min-max \
      -c org.apache.druid.extensions.contrib:druid-virtual-columns

RUN rm -f apache-druid-$DRUID_VERSION-bin.tar.gz \
 && tar -cvf apache-druid-$DRUID_VERSION-bin.tar.gz apache-druid-$DRUID_VERSION

