#!/bin/sh


MCSDIR=/usr/local/mariadb/columnstore
mysql=( $MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot )
#TODO: Config those IP Addresses
${mysql[@]} - e "grant replication slave on *.* to idbrep@10.5.0.1 identified by 'Calpont1'";
${mysql[@]} - e "grant all on *.* to idbrep@10.5.0.1 identified by 'Calpont1';";

MAX_TRIES=36
if [ ! -z "$CS_WAIT_ATTEMPTS" ]; then
    MAX_TRIES=$CS_WAIT_ATTEMPTS
fi

# if argument is -d enable debug output
if [ $# -gt 0 ] && [ "$1" == "-d" ]; then
    MARIADB_CS_DEBUG=1
fi

if [ ! -z $MARIADB_CS_DEBUG ]; then
    #set +x
    echo '------------------------------'
    echo 'Starting UM Master Post Install'
    echo '------------------------------'
    #set -x
fi

echo "Waiting for UM2 to respond"
ATTEMPT=1
# this essential waits for the root @um1 login to be created as well as the slave to be started.
STATUS=$(${mysql[@]} -h um2 -e "show slave status\G" | grep "Waiting for master")
while [ 1 -eq $? ] && [ $ATTEMPT -le $MAX_TRIES ]; do
    if [ ! -z $MARIADB_CS_DEBUG ]; then
        echo "wait_for_um2_slave_start($ATTEMPT/$MAX_TRIES): $STATUS"
    fi
    sleep 5
    ATTEMPT=$(($ATTEMPT+1))
    STATUS=$("${mysql[@]}" -h um2 -e "show slave status\G" | grep "Waiting for master")
done

if [ $ATTEMPT -ge $MAX_TRIES ]; then
    echo "ERROR: Did not detect slave start on um2 after $MAX_TRIES attempts, last status: $STATUS"
    exit 1
fi

exit 0
