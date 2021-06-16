#!/bin/bash
sudo /usr/sbin/sshd

sudo chown -R gpadmin:gpadmin /var/lib/gpdb/data

source ${GPHOME}/greenplum_path.sh

m="master"
if [ "$GP_NODE" == "$m" ]
then
    echo 'Node type='$GP_NODE
    if [ ! -d $MASTER_DATA_DIRECTORY ]; then
        echo 'Master directory does not exist. Initializing master from gpinitsystem_reflect.'
        yes | cp $HOSTFILE hostlist
        gpssh-exkeys -f hostlist
        echo "Key exchange complete"
        gpinitsystem -a -c gpinitsys --su_password=dataroad -h hostlist
        echo "Master node initialized"
        # receive connection from anywhere.. This should be changed!!
        echo "host all all 0.0.0.0/0 md5" >>$MASTER_DATA_DIRECTORY/pg_hba.conf
        echo 'pg_hba.conf changed. Reload config without restart gpdb.'
        gpstop -u
    else
        echo 'Master exists. Starting gpdb.'
        gpstart -a
    fi
else
    echo 'Node type='$GP_NODE
fi
exec "$@"
