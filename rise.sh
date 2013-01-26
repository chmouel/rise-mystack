#!/bin/bash
set -x
set -e

function readlink { [[ $1 == "-f" ]] && shift; [[ -z $1 ]] && return;python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $1 ;}

SERVER_NAME=${1:-devstack.rackspaceclouduk.com}
SHORT_SERVER_NAME=${SERVER_NAME%%.*}
DOMAIN_NAME=${SERVER_NAME#*.}
IMAGE_NAME=risedevstack.rackspaceclouduk.com
FLAVOR_ID=4
MAX_WAIT=30

IMAGE_ID=$(nova image-list | awk "/${IMAGE_NAME}/ { print \$2 }")
MYDIR=$( dirname $(readlink -f $0))

if [[ -z ${IMAGE_ID} ]];then
    echo "Cannot find IMAGE_NAME ${IMAGE_NAME}"
    exit 1;
fi

set -e

function delete_server() {
    ID=$(nova list --name "^${SERVER_NAME}$"|awk "/${SERVER_NAME}/ {print \$2}")
    [[ -z ${ID} ]] && return 0
    nova delete ${ID}

    cnt=0
    while [[ ${cnt} != ${MAX_WAIT} ]];do
        ID=$(nova list --status ACTIVE --name "^${SERVER_NAME}$")
        [[ -n ${ID} ]] || return 0
        sleep 10
        (( cnt += 1 ))
    done

    echo "Cannot Delete server"
    exit 1
}

function create_server() {
    nova boot --poll --flavor ${FLAVOR_ID} --image ${IMAGE_ID} ${SERVER_NAME}
}

function rebuild_server() {
    ID=$(nova list --name "^${SERVER_NAME}$"|awk "/${SERVER_NAME}/ {print \$2}")
    if [[ -n ${ID} ]];then
        nova rebuild --poll ${ID} ${IMAGE_ID}
    else
       create_server
    fi
}

rebuild_server

NEWID=$(nova list --status ACTIVE --name "^${SERVER_NAME}$"|awk "/${SERVER_NAME}/ {print \$2}")
if [[ -z ${NEWID} ]];then
    echo "Error while creating server"
    exit 1
fi
NEWIP=$(nova show ${NEWID}|awk '/accessIPv4/ { print $4}')

if [[ -z ${NEWIP} ]];then
    echo "Error while getting new server"
    exit 1
fi


# Update new domain name directly in DNS.
${MYDIR}/updatedomain.py ${DOMAIN_NAME} ${SHORT_SERVER_NAME} ${NEWIP} || :

if egrep -q "Host ${SERVER_NAME} ${SHORT_SERVER_NAME}$" ${HOME}/.ssh/config;then
   sed -i~ "/Host ${SERVER_NAME} ${SHORT_SERVER_NAME}$/,/Host|$/ { s/Hostname.*/Hostname ${NEWIP}/;}" ${HOME}/.ssh/config
else
    echo -e "Host ${SERVER_NAME} ${SHORT_SERVER_NAME}\n    Hostname ${NEWIP}\n" > /tmp/.sshconfig.$$
    cat ~/.ssh/config >> /tmp/.sshconfig.$$
    cp -f ~/.ssh/config ~/.ssh/config~
    cp -f /tmp/.sshconfig.$$ ~/.ssh/config
fi

for x in ${SERVER_NAME} ${SHORT_SERVER_NAME};do
    ssh-keygen -f "${HOME}/.ssh/known_hosts" -R $x
done

scp -q ${MYDIR}/functions.zsh stack@${SERVER_NAME}:.shell/hosts/${SHORT_SERVER_NAME}.sh
ssh -t -q stack@${SERVER_NAME} "sed -i -e 's/@UK_RCLOUD_KEY@/${UK_RCLOUD_KEY}/' -e 's/@UK_RCLOUD_USER@/${UK_RCLOUD_USER}/' .shell/hosts/${SHORT_SERVER_NAME}.sh "
scp -q ${MYDIR}/upvm.sh stack@${SERVER_NAME}:/tmp
ssh -t -q stack@${SERVER_NAME} "sudo bash /tmp/upvm.sh"
ssh -t -q stack@${SERVER_NAME} "grep -qrw 'devstack$' /etc/hosts || sudo sed -i '/${SHORT_SERVER_NAME}/ { s/$/ ${SHORT_SERVER_NAME}/ }' /etc/hosts;mkdir -p bin/"

scp -q ${MYDIR}/local* stack@${SERVER_NAME}:devstack/
scp -q ${MYDIR}/bin/* stack@${SERVER_NAME}:bin/

ssh stack@${SERVER_NAME} "echo HOST_IP=${NEWIP}|tee -a devstack/localrc >/dev/null"
