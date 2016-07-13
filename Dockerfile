# Use phusion/baseimage as base image. To make your builds
# reproducible, make sure you lock down to a specific version, not
# to `latest`! See
# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# for a list of version numbers.
FROM phusion/baseimage:0.9.4

EXPOSE 50070 50095 2181 9997 9000

# Use baseimage-docker's init system.
RUN rm -f /etc/service/sshd/down
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
CMD ["/sbin/my_init"]

RUN apt-get update
RUN apt-get install -y openjdk-7-jdk wget

# Environment variables
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64/
ENV HADOOP_HOME /root/installs/hadoop-2.6.3
ENV ZOOKEEPER_HOME /root/installs/zookeeper-3.4.6

#Change this setting for performances
RUN sed -i 's/securerandom.source=file:\/dev\/urandom/securerandom.source=file:\/dev\/\.\/urandom/' $JAVA_HOME/jre/lib/security/java.security

RUN ssh-keygen -f ~/.ssh/id_rsa -P ''
RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN echo "Host *" >> /etc/ssh/ssh_config && echo "   StrictHostKeyChecking no" >> /etc/ssh/ssh_config && echo "   UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
RUN mkdir -p /root/downloads
WORKDIR /root/downloads
RUN wget http://it.apache.contactlab.it/hadoop/common/hadoop-2.6.3/hadoop-2.6.3.tar.gz
RUN wget http://apache.panu.it/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz
RUN wget http://it.apache.contactlab.it/accumulo/1.6.5/accumulo-1.6.5-bin.tar.gz
RUN mkdir -p /root/installs
WORKDIR /root/installs
RUN tar zxvf /root/downloads/hadoop-2.6.3.tar.gz
RUN tar zxvf /root/downloads/zookeeper-3.4.6.tar.gz
RUN tar zxvf /root/downloads/accumulo-1.6.5-bin.tar.gz

RUN sed -i 's/<configuration>/<configuration>\n\t<property>\n\t\t<name>fs.defaultFS<\/name>\n\t\t<value>hdfs:\/\/localhost:9000<\/value>\n\t<\/property>/' hadoop-2.6.3/etc/hadoop/core-site.xml

RUN sed -i 's/<configuration>/\
<configuration>\n\
    <property>\n\
        <name>dfs.replication<\/name>\n\
        <value>1<\/value>\n\
    <\/property>\n\
    <property>\n\
        <name>dfs.name.dir<\/name>\n\
        <value>hdfs_storage\/name<\/value>\n\
    <\/property>\n\
    <property>\n\
        <name>dfs.data.dir<\/name>\n\
        <value>hdfs_storage\/data<\/value>\n\
    <\/property>\n\
/' hadoop-2.6.3/etc/hadoop/hdfs-site.xml

RUN printf '\
<?xml version="1.0"?>\n\
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>\n\
<configuration>\n\
     <property>\n\
         <name>mapred.job.tracker</name>\n\
         <value>localhost:9001</value>\n\
     </property>\n\
</configuration>\n\
' >> hadoop-2.6.3/etc/hadoop/mapred-site.xml

RUN sed -i 's/export JAVA_HOME=${JAVA_HOME}/export JAVA_HOME=\/usr\/lib\/jvm\/java-7-openjdk-amd64/' hadoop-2.6.3/etc/hadoop/hadoop-env.sh

WORKDIR /root/installs/hadoop-2.6.3

RUN cp ~/installs/zookeeper-3.4.6/conf/zoo_sample.cfg ~/installs/zookeeper-3.4.6/conf/zoo.cfg

RUN cp ~/installs/accumulo-1.6.5/conf/examples/512MB/native-standalone/* ~/installs/accumulo-1.6.5/conf/
RUN sed -i 's/# export ACCUMULO_MONITOR_BIND_ALL="true"/export ACCUMULO_MONITOR_BIND_ALL="true"/' ~/installs/accumulo-1.6.5/conf/accumulo-env.sh
RUN sed -i 's/<value>DEFAULT<\/value>/<value>password<\/value>/' ~/installs/accumulo-1.6.5/conf/accumulo-site.xml
RUN sed -i 's/<value>secret<\/value>/<value>password<\/value>/' ~/installs/accumulo-1.6.5/conf/accumulo-site.xml
RUN sed -i 's/<\/configuration>/\
<property>\n\
    <name>instance.volumes<\/name>\n\
    <value>hdfs:\/\/localhost:9000\/accumulo<\/value>\n\
<\/property>\n\
<\/configuration>\n\
/' ~/installs/accumulo-1.6.5/conf/accumulo-site.xml

ADD sshd_start.sh /etc/my_init.d/01_sshd_start.sh
ADD hadoop_format_hdfs.sh /etc/my_init.d/02_hadoop_format_hdfs.sh
ADD hadoop_start.sh /etc/my_init.d/03_hadoop_start.sh
ADD zookeeper_start.sh /etc/my_init.d/04_zookeeper_start.sh
ADD accumulo_init.sh /etc/my_init.d/05_accumulo_init.sh
ADD accumulo_start.sh /etc/my_init.d/06_accumulo_start.sh

RUN rm -f /root/downloads/*
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
