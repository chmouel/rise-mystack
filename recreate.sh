#!/bin/bash
set -x

SERVER_NAME=${1:-devstack.rackspaceclouduk.com}
SHORT_SERVER_NAME=${SERVER_NAME%%.*}
DOMAIN_NAME=${SERVER_NAME#*.}
IMAGE_ID=11010395
FLAVOR_ID=3
#export RCLOUD_DATACENTER=US

MYDIR=$( dirname $(readlink -f $0))

set -e
cd ~/GIT/rackspace/api-demo/python

function create_server() {
    ./delete-servers.py -s ${SERVER_NAME} -f
    ./create.py -B -n ${SERVER_NAME} -f ${FLAVOR_ID} -i $IMAGE_ID
    sleep 20
}
create_server

NEWIP=$(python ${MYDIR}/getip.py ${SERVER_NAME})

if [[ -z ${NEWIP} ]];then
    echo "Error i'm sorry!"
    exit 1
fi

sudo sed -i "/${SERVER_NAME}/d" /etc/hosts

# Update new domain name directly in DNS.
$HOME/bin/updatedomain.py ${DOMAIN_NAME} ${SHORT_SERVER_NAME} ${NEWIP} || :

echo "$NEWIP $SERVER_NAME $SHORT_SERVER_NAME" | sudo tee -a /etc/hosts

cd ~/GIT/openstack/

for x in ${SERVER_NAME} ${SHORT_SERVER_NAME};do
    ssh-keygen -f "/home/chmouel/.ssh/known_hosts" -R $x
done

scp -q ${MYDIR}/upvm.sh root@${SERVER_NAME}:/tmp
ssh -t -q root@${SERVER_NAME} "bash /tmp/upvm.sh"

rsync -v -auz /var/lib/lxc/shared/GIT/openstack/devstack stack@${SERVER_NAME}:

scp -q ${MYDIR}/localrc stack@${SERVER_NAME}:devstack/localrc
