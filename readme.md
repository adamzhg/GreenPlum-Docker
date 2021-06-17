# greenplum-docker
Docker for greenplum (6) database.

## Build

```sh
docker build -t greenplum:6 .
```

or use apt-get mirror like `mirrors.aliyun.com`

```sh
docker build -t greenplum:6 . --build-arg APT_MIRROR=mirrors.aliyun.com 
```

## Single Node Docker

From the command line execute the following command:
```sh
docker run -it -p 5432:5432 --hostname=db_master_1 greenplum:6 bash
```

Connect to your host on port 5432 user/pass is gpadmin/dataroad

## Multi Node Docker-Compose

From the command line execute the following command: 
```sh
docker compose up
```

You can connect to your host using PGADMIN on port 5432 user/pass is gpadmin/dataroad

## Swarm Multi Node Docker-Compose

From the command line execute the following command: 
```sh
docker stack deploy -c docker-compose-stack.yml greenplum-stack
```

You can connect to your host using PGADMIN on port 5432 user/pass is gpadmin/dataroad

### singlehost

This file contains the name of the hosts to connect to. 
By default there is one host 'db_master_1'.
Will create two segment on one host

### multihost

This file contains the name of the segments that the master connects to. 
This is used when running a multi-node cluster and has 4 segments (each node have 2 segments) in it.

### gpinitsys

Configuration file for setting up the greenplum cluster.


## Questions?

chad@caoanalytics.com
@xiaoyao9184


