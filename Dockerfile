FROM ubuntu:16.04


######### Oracle Java magic BEGIN #########
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" > /etc/apt/sources.list.d/webupd8team-java.list
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886 && \
    apt-get update && \
    apt-get install -y oracle-java8-installer && \
    rm -rf /var/cache/oracle-jdk8-installer

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
########## Oracle Java magic END ##########


###### Druid install BEGIN ######

ENV DRUID_VERSION 0.9.2-rc1
ENV DRUID_HOME /opt/druid
ENV DRUID_MAVEN_REPO https://metamx.artifactoryonline.com/metamx/libs-releases

RUN wget -q -O - http://static.druid.io/artifacts/releases/druid-$DRUID_VERSION-bin.tar.gz | tar -xzf - -C /opt && \
    ln -s /opt/druid-$DRUID_VERSION $DRUID_HOME && \
    rm -rf $DRUID_HOME/conf/ && \
    wget -q -O - http://static.druid.io/artifacts/releases/mysql-metadata-storage-$DRUID_VERSION.tar.gz | tar -xzf - -C $DRUID_HOME/extensions && \
    mv $DRUID_HOME/extensions/mysql-metadata-storage/mysql-connector-java-*.jar $DRUID_HOME/lib

# Install extension libraries
#RUN mvn org.apache.maven.plugins:maven-dependency-plugin:2.1:get \
#        -DrepoUrl=$DRUID_MAVEN_REPO -Dartifact=io.druid.extensions:mysql-metadata-storage:$DRUID_VERSION && \
#RUN mvn org.apache.maven.plugins:maven-dependency-plugin:2.1:get \
#        -DrepoUrl=$DRUID_MAVEN_REPO -Dartifact=io.druid.extensions:druid-hdfs-storage:$DRUID_VERSION && \
#    mvn org.apache.maven.plugins:maven-dependency-plugin:2.1:get \
#        -DrepoUrl=$DRUID_MAVEN_REPO -Dartifact=io.druid.extensions:druid-s3-extensions:$DRUID_VERSION
#    mvn org.apache.maven.plugins:maven-dependency-plugin:2.1:get \
#        -DrepoUrl=$DRUID_MAVEN_REPO -Dartifact=org.apache.hadoop:hadoop-client:2.6.0

ADD conf $DRUID_HOME/conf/

######## Cleanup
RUN apt-get autoremove -y &&                \
    apt-get clean &&                        \
    rm -rf /var/lib/apt/lists/* &&          \
    rm -rf /var/cache/debconf


######## Final phase

ADD bin/entry.sh $DRUID_HOME/bin/

ENTRYPOINT $DRUID_HOME/bin/entry.sh

