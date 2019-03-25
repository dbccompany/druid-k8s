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

COPY . /tmp/build

RUN cd /tmp/build \
 && mvn clean install -Pdist -DskipTests
