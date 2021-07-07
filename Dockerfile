FROM ubuntu:18.04

ARG APT_MIRROR="archive.ubuntu.com"

RUN sed -i "s@/archive.ubuntu.com/@/$APT_MIRROR/@g"  /etc/apt/sources.list
# ARG APT_MIRROR_ARCHIVE="archive.ubuntu.com"
# ARG APT_MIRROR_SECURITY="security.ubuntu.com"
# RUN sed -i "s@/archive.ubuntu.com/@/$APT_MIRROR_ARCHIVE/@g"  /etc/apt/sources.list \
#     && sed -i "s@/security.ubuntu.com/@/$APT_MIRROR_SECURITY/@g"  /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:greenplum/db \
    && apt-get update \
    && apt-get install -y greenplum-db-6 \
    && apt-get install -y less vim sudo openssh-server locales iputils-ping dnsutils curl gawk

RUN curl -fsSL https://get.docker.com | bash

RUN GPVERSION=$(ls /opt/ | grep -i "greenplum-db" | sed 's/greenplum-db-//g') \
    && ln -s /opt/greenplum-db-${GPVERSION} /opt/gpdb

# set locale
RUN locale-gen en_US.UTF-8  
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8 

# create master directory
RUN mkdir -p /var/lib/gpdb/data/gpmaster
# create data directory
RUN mkdir -p /var/lib/gpdb/data/gpdata

# add config & script
WORKDIR /var/lib/gpdb/setup/
ADD multihost .
ADD singlehost .
ADD gpinitsys .

# create gpadmin user
ADD gpadmin_user.sh .
RUN chmod 755 gpadmin_user.sh
RUN ./gpadmin_user.sh
RUN usermod -aG sudo gpadmin

# sshd must exist for gpdb monitor_master.sh
ADD monitor_master.sh .
RUN chmod +x monitor_master.sh
RUN echo 'gpadmin ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# auto create hostlist when not exist
ADD swarm_service_ip_scan.sh .
RUN chmod +x swarm_service_ip_scan.sh

ADD swarm_service_replicas_get.sh .
RUN chmod +x swarm_service_replicas_get.sh

# gpadmin must have permission to write to these directories
RUN chown -R gpadmin:gpadmin /var/lib/gpdb

# add the entrypoint script
ADD docker-entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh


USER gpadmin

ENV USER=gpadmin
ENV MASTER_DATA_DIRECTORY=/var/lib/gpdb/data/gpmaster/gpsne-1
ENV GPHOME=/opt/gpdb
ENV PYTHONHOME=${GPHOME}/ext/python
ENV PATH=${PYTHONHOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${PYTHONHOME}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
ENV PYTHONPATH=${GPHOME}/lib/python
ENV PATH=${GPHOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${GPHOME}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
ENV OPENSSL_CONF=${GPHOME}/etc/openssl.cnf

#CHANGE THIS with docker command or docker-compose
ENV GP_NODE=master
ENV HOSTFILE=singlehost

VOLUME /var/lib/gpdb/data
ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 5432

CMD ["./monitor_master.sh"]
