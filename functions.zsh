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
alias inst="sudo apt-get -y install"
alias remove="sudo apt-get -y remove"
alias u="upcs -cpublic"

alias swiftv1='ST_USER=admin:admin ST_AUTH="http://localhost:8080/auth/v1.0" ST_KEY=admin swift stat'


function soso {
    pushd ~/devstack >/dev/null && {
        eval $(bash -c ". openrc $1 $2;env|sed -n '/OS_/ { s/^/export /;p}'")
    } && popd >/dev/null
}

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

unset USERNAME

[[ -e /usr/share/autojump/autojump.sh ]] && source /usr/share/autojump/autojump.sh

