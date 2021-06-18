#!/bin/bash
sudo /usr/sbin/sshd

sudo chown -R gpadmin:gpadmin /var/lib/gpdb/data

source ${GPHOME}/greenplum_path.sh

if [ "$GP_NODE" == "master" ]
then
    echo 'Node type='$GP_NODE
    if [ ! -f $HOSTFILE ]; then
        echo 'hostfile not exist. Automatically generated it use environment variable GP_SEG_DOMAIN through DNS.'
        
        if [[ -z "$GP_SEG_DOMAIN" ]]; then
            GP_SEG_DOMAIN="tasks.db_seg"
        fi

        ./swarm_service_replicas_get.sh $GP_SEG_DOMAIN
        tar_replicas=$?
        if [[ $tar_replicas -ne 0 ]]; then
            echo "Need $tar_replicas hosts as clusters"
        else
            echo "WARNING: cant determine the number of hosts clusters. Continue when scanning more than 1 host."
            tar_replicas=1
        fi

        host_count=0
        until [[ $host_count -ge $tar_replicas ]]; do
            sleep 1
            echo "Scanning swarm service ip..."
            rm -f $HOSTFILE
            ./swarm_service_ip_scan.sh $GP_SEG_DOMAIN $HOSTFILE
            if [[ $? -ne 0 ]]; then
                echo "ERROR: create hostfile error."
            fi

            host_count=$(cat $HOSTFILE | wc -l)
            host_count=$((host_count-1))
            echo "Scan result $host_count IP of service."
        done
    fi

    if [ ! -f hostlist ]; then
        yes | cp $HOSTFILE hostlist
    fi

    if [ ! -d $MASTER_DATA_DIRECTORY ]; then
        echo 'Master directory does not exist. Initializing master from gpinitsystem_reflect.'
        
        # Already configured, because the ssh key of all docker images is the same
        # gpssh-exkeys -f hostlist
        # if [[ $? -ne 0 ]]; then
        #     echo "ERROR: gpssh-exkeys error."
        #     exit 1
        # fi
        # echo "Key exchange complete"

        if [[ -z "$GP_PASSWD" ]]; then
            echo "WARNING: missing password of gpdb gpadmin, use default 'dataroad'"
            GP_PASSWD="dataroad"
        fi

        gpinitsystem -a -c gpinitsys --su_password=$GP_PASSWD -h hostlist
        if [[ $? -ne 0 ]]; then
            echo "ERROR: gpinitsystem error."
        else
            echo "Master node initialized"
        fi
        if [[ -f "$MASTER_DATA_DIRECTORY/pg_hba.conf" ]]; then
            # receive connection from anywhere.. This should be changed!!
            echo "host all all 0.0.0.0/0 md5" >>$MASTER_DATA_DIRECTORY/pg_hba.conf
            echo 'pg_hba.conf changed. Reload config without restart gpdb.'
            gpstop -u
        fi
    else
        echo 'Master exists. Starting gpdb.'
        gpstart -a
    fi
    if [[ $? -ne 0 ]]; then
        echo "ERROR: gpdb start error."
        exit 1
    fi
else
    echo 'Node type='$GP_NODE
    echo "Ready."
fi
exec "$@"
