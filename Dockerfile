# Use phusion/baseimage as base image. To make your builds
# reproducible, make sure you lock down to a specific version, not
# to `latest`! See
# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# for a list of version numbers.
FROM phusion/baseimage:0.9.4

# Use baseimage-docker's init system.
RUN rm -f /etc/service/sshd/down
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
CMD ["/sbin/my_init"]

RUN apt-get update
RUN apt-get install -y openjdk-7-jdk wget
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64/
RUN sed -i 's/securerandom.source=file:\/dev\/urandom/securerandom.source=file:\/dev\/\.\/urandom/' $JAVA_HOME/jre/lib/security/java.security
RUN ssh-keygen -f ~/.ssh/id_rsa -P ''
RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN echo "Host *" >> /etc/ssh/ssh_config && echo "   StrictHostKeyChecking no" >> /etc/ssh/ssh_config && echo "   UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
RUN mkdir -p /root/downloads
WORKDIR /root/downloads
RUN wget http://apache.panu.it/hadoop/common/hadoop-2.7.2/hadoop-2.7.2.tar.gz
RUN wget http://apache.panu.it/zookeeper/stable/zookeeper-3.4.6.tar.gz
RUN wget http://mirror.nohup.it/apache/accumulo/1.7.0/accumulo-1.7.0-bin.tar.gz
RUN mkdir -p /root/installs
WORKDIR /root/installs
RUN tar zxvf /root/downloads/hadoop-2.7.2.tar.gz
RUN tar zxvf /root/downloads/zookeeper-3.4.6.tar.gz
RUN tar zxvf /root/downloads/accumulo-1.7.0-bin.tar.gz

RUN sed -i 's/<configuration>/<configuration>\n\t<property>\n\t\t<name>fs.defaultFS<\/name>\n\t\t<value>hdfs:\/\/localhost:9000<\/value>\n\t<\/property>/' hadoop-2.7.2/etc/hadoop/core-site.xml

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
/' hadoop-2.7.2/etc/hadoop/hdfs-site.xml

RUN printf '\
<?xml version="1.0"?>\n\
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>\n\
<configuration>\n\
     <property>\n\
         <name>mapred.job.tracker</name>\n\
         <value>localhost:9001</value>\n\
     </property>\n\
</configuration>\n\
' >> hadoop-2.7.2/etc/hadoop/mapred-site.xml

RUN hadoop-2.7.2/bin/hdfs namenode -format
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
