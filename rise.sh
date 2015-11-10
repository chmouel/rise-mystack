#!/bin/bash
set -x
set -e

[[ $1 == "-s" ]] && { SKIP_REBUILD=true; shift ;}

function readlink { [[ $1 == "-f" ]] && shift; [[ -z $1 ]] && return;python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $1 ;}

CONFIG_FILE=$1
FLAVOR_ID=4
MAX_WAIT=30
SSH_KEY_NAME=Chmouel

SERVER_NAME=devstack.chmouel.com
CLOUD_USER=fedora
OPENSTACK_SETUP=no

source ${CONFIG_FILE}

if [[ -z ${IMAGE_NAME} ]];then
    echo "I need a IMAGE_NAME"
    exit 1
elif [[ -z ${CONFIG_FILE} ]];then
    echo "I need a configuration file"
    exit 1
elif [[ -z ${SERVER_NAME} ]];then
    echo "I need a SERVER_NAME"
    exit 1
fi


MYDIR=$( dirname $(readlink -f $0))
NOVA_BIN=${HOME}/bin/novaeno
NOVA_BIN=nova
DOMAIN_NAME=${SERVER_NAME#*.}
SHORT_SERVER_NAME=${SERVER_NAME%%.*}

function create_server() {
    ${NOVA_BIN} boot --poll --key-name ${SSH_KEY_NAME} --flavor=${FLAVOR_ID} --image=${IMAGE_ID} \
        --security-groups default ${SERVER_NAME}
    sleep 1
    if [[ -n ${PUBLIC_IP} ]];then
        ${NOVA_BIN} remove-floating-ip ${SERVER_NAME} ${PUBLIC_IP} || :
        ${NOVA_BIN} add-floating-ip ${SERVER_NAME} ${PUBLIC_IP}
    fi
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
[[ -z ${SKIP_REBUILD} ]] && rebuild_server

for x in ${SERVER_NAME} ${SHORT_SERVER_NAME} ${JUMP_HOST_TARGET_IP} ${PUBLIC_IP};do
    ssh-keygen -f "${HOME}/.ssh/known_hosts" -R $x
done

if [[ -n ${JUMP_HOST_TARGET_IP} ]];then
     ssh ${JUMP_USER:-${CLOUD_USER}}@${JUMP_HOST} "[[ -e ~/.ssh/known_hosts ]] || exit 0;for x in ${JUMP_HOST_TARGET_IP} ${SERVER_NAME} ${PUBLIC_IP}; do ssh-keygen -f ~/.ssh/known_hosts -R \$x;done"
fi

function _scmd () {
    type=$1
    shift
    cmd=$@

    if [[ -n ${JUMP_HOST_TARGET_IP} ]];then
       cmd=${cmd/$CLOUD_USER@$SERVER_NAME/$CLOUD_USER@$JUMP_HOST_TARGET_IP}
    fi
    if [[ -n ${JUMP_HOST} ]];then
        ${type} -o ProxyCommand="ssh -W %h:%p ${JUMP_USER:-${CLOUD_USER}}@${JUMP_HOST}" ${cmd}
    else
        ${type} ${cmd}
    fi
}

_scmd scp ${proxy_command} bootstrap.sh upvm.sh bootstrap-pre.sh ${CLOUD_USER}@${SERVER_NAME}:/tmp/
_scmd ssh -t ${CLOUD_USER}@${SERVER_NAME} bash /tmp/bootstrap-pre.sh
_scmd ssh -t ${CLOUD_USER}@${SERVER_NAME} "export RHEL_USER=${RHEL_USER} RHEL_POOL=${RHEL_POOL} RHEL_PASSWORD=${RHEL_PASSWORD} OPENSTACK_SETUP=${OPENSTACK_SETUP};bash -x /tmp/bootstrap.sh && sudo -E bash -x /tmp/upvm.sh"

_scmd scp -q ${MYDIR}/functions.zsh ${CLOUD_USER}@${SERVER_NAME}:.shell/hosts/${SHORT_SERVER_NAME}.sh

[[ -n ${LOCAL_SCRIPT} && -f $(dirname ${CONFIG_FILE})/${LOCAL_SCRIPT} ]] && LOCAL_SCRIPT=$(dirname ${CONFIG_FILE})/${LOCAL_SCRIPT} 

if [[ -n ${LOCAL_SCRIPT} && -f ${LOCAL_SCRIPT} ]];then
    _scmd scp -q ${LOCAL_SCRIPT} ${CLOUD_USER}@${SERVER_NAME}:/tmp/.local
    _scmd ssh -t ${CLOUD_USER}@${SERVER_NAME} "chmod +x /tmp/.local;/tmp/.local"
fi

if [[ ${OPENSTACK_SETUP} == "yes" ]]; then
    _scmd scp -q ${MYDIR}/openstack/local* ${CLOUD_USER}@${SERVER_NAME}:devstack/
    _scmd ssh ${CLOUD_USER}@${SERVER_NAME} '[[ -e /usr/bin/autojump ]] || exit;mkdir -p ~/.local/share/autojump;for i in /opt/stack/*;do autojump -a $i;done'
fi
