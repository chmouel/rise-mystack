#!/bin/bash
set -x
set -e

function readlink { [[ $1 == "-f" ]] && shift; [[ -z $1 ]] && return;python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $1 ;}

PUBLIC_IP=46.231.128.140
FLAVOR_ID=4
MAX_WAIT=30
SSH_KEY_NAME=Chmouel

SERVER_NAME=devstack.chmouel.com
IMAGE_NAME="ubuntu-raring"

[[ -n $1 && -e $1 ]] && source $1

MYDIR=$( dirname $(readlink -f $0))
NOVA_BIN=${HOME}/bin/novaeno
NOVA_BIN=nova
DOMAIN_NAME=${SERVER_NAME#*.}
SHORT_SERVER_NAME=${SERVER_NAME%%.*}

function create_server() {
    ${NOVA_BIN} boot --poll --key-name ${SSH_KEY_NAME} --flavor=${FLAVOR_ID} --image=${IMAGE_ID} \
        --security-groups default ${SERVER_NAME}
    sleep 1
    ${NOVA_BIN} remove-floating-ip ${SERVER_NAME} ${PUBLIC_IP}
    ${NOVA_BIN} add-floating-ip ${SERVER_NAME} ${PUBLIC_IP}
}

function rebuild_server() {
    IMAGE_ID=$(${NOVA_BIN} image-list | awk "/${IMAGE_NAME}/ { print \$2 }")
    if [[ -z ${IMAGE_ID} ]];then
       echo "Cannot find IMAGE_NAME ${IMAGE_NAME}"
       exit 1;
    fi

    ID=$(${NOVA_BIN} list --name "^${SERVER_NAME}$"|awk "/${SERVER_NAME}/ {print \$2}")
    if [[ -n ${ID} ]];then
        ${NOVA_BIN} rebuild --poll ${ID} ${IMAGE_ID}
        read -t 90 || true
    else
       create_server
    fi
}
rebuild_server

for x in ${SERVER_NAME} ${SHORT_SERVER_NAME} ${PUBLIC_IP};do
    ssh-keygen -f "${HOME}/.ssh/known_hosts" -R $x
done

scp bootstrap.sh upvm.sh bootstrap-pre.sh ubuntu@${SERVER_NAME}:/tmp/
ssh ubuntu@${SERVER_NAME} bash /tmp/bootstrap-pre.sh
ssh stack@${SERVER_NAME} "bash /tmp/bootstrap.sh && sudo bash /tmp/upvm.sh"

scp -q ${MYDIR}/functions.zsh stack@${SERVER_NAME}:.shell/hosts/${SHORT_SERVER_NAME}.sh
[[ -e ~/.config/rackspace-cloud/config ]] && {
    source ~/.config/rackspace-cloud/config
    ssh -t -q stack@${SERVER_NAME} "sed -i -e 's/@UK_RCLOUD_KEY@/${UK_RCLOUD_KEY}/' -e 's/@UK_RCLOUD_USER@/${UK_RCLOUD_USER}/' .shell/hosts/${SHORT_SERVER_NAME}.sh "
}
scp -q ${MYDIR}/local* stack@${SERVER_NAME}:devstack/
scp -q ${MYDIR}/bin/* stack@${SERVER_NAME}:bin/
scp -rq ${MYDIR}/tests stack@${SERVER_NAME}:
ssh stack@${SERVER_NAME} "echo HOST_IP=${PUBLIC_IP}|tee -a devstack/localrc >/dev/null;chmod +x devstack/local.sh"
ssh stack@${SERVER_NAME} 'mkdir -p ~/.local/share/autojump;for i in /opt/stack/*;do autojump -a $i;done'
