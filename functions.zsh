# -*- Mode: shell-script -*-
userColor="green"
hostColor="green"

export UK_RCLOUD_USER=@UK_RCLOUD_USER@
export UK_RCLOUD_KEY=@UK_RCLOUD_KEY@
export UK_RCLOUD_AURL=https://lon.auth.api.rackspacecloud.com/v1.0

alias -g MJ="|python -mjson.tool"
alias -g SP="|curl -F 'sprunge=<-' http://sprunge.us"
alias so_os=soso
alias so_os_admin="soso admin admin" 
OS_TENANT_NAME=swifttenanttest1 OS_USERNAME=swiftusertest1 OS_PASSWORD=testing
alias so_os_testuser="so_os;export OS_TENANT_NAME=swifttenanttest1 OS_USERNAME=swiftusertest1 OS_PASSWORD=testing"
alias so_euc="pushd ~/devstack >/dev/null && source eucarc && popd >/dev/null"


if [[ -e /usr/bin/yum ]];then
    alias inst="sudo yum -y install"
    alias remove="sudo yum -y remove"
    alias search="sudo yum search"
else
    alias inst="sudo apt-get -y install"
    alias remove="sudo apt-get -y remove"
    alias search="apt-cache search"
fi

alias u="upcs -cpublic"

alias swiftv1='ST_USER=admin:admin ST_AUTH="http://localhost:8080/auth/v1.0" ST_KEY=admin swift stat'


function soso {
    [[ -d ~/devstack ]] || return
    eval $(for i in $(env|grep OS_);do echo -n "export ";echo -n ${i%%=*};echo =;done)
    pushd ~/devstack >/dev/null && {
        eval $(bash -c ". openrc $1 $2;env|sed -n '/OS_/ { s/^/export /;p}'")
    } && popd >/dev/null
}
soso >/dev/null

function gd() {
    arg=$1

    if [[ ${arg} == http* ]];then
        [[ ${arg} == */c/* ]] && arg=$(echo ${arg}|sed 's,.*/c/,,;s,/.*,,')
        [[ ${arg} =~ "/([0-9]{4,})$" ]] && arg=${MATCH[2,-1]}
    fi
    if [[ ${arg} =~ "^[0-9]{4,}$" ]];then
        :
    else
        echo "I could not figure out what review this is: ${arg}"
        return 1
    fi
    git-review -d ${arg}
}

function os_complete {
    local comp=$1
    local d=/opt/stack/python-${1}client/tools/${comp}.bash_completion

    [[ -e ${d} ]] || { echo "No project ${comp}"; return 1;}

    autoload -U bashcompinit
    bashcompinit
    source ${d}

}

function vin() { vim $(fin $1) ;}
function rejoin_stack() {
     mount | grep -q /opt/stack/data/swift/drives/images/swift.img || \
         sudo mount -t xfs -o loop,noatime,nodiratime,nobarrier,logbufs=8 \
            /opt/stack/data/swift/drives/images/swift.img  /opt/stack/data/swift/drives/sdb1
    mkdir -p /tmp/screen-logs
    sed -i '/^hardstatus/ { s/.*/source ~\/.screenrc\n/}' ~/devstack/stack-screenrc
    cd ~/devstack
    ./rejoin-stack.sh
}

unset USERNAME

[[ -e /usr/share/autojump/autojump.sh ]] && source /usr/share/autojump/autojump.sh

