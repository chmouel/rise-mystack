# -*- Mode: shell-script -*-
userColor="green"
hostColor="green"

export UK_RCLOUD_USER=@UK_RCLOUD_USER@
export UK_RCLOUD_KEY=@UK_RCLOUD_KEY@
export UK_RCLOUD_AURL=https://lon.auth.api.rackspacecloud.com/v1.0

alias g="git grep"
alias -g MJ="|python -mjson.tool"
alias -g SP="|curl -F 'sprunge=<-' http://sprunge.us"
alias so_os="pushd ~/devstack >/dev/null && source openrc && popd >/dev/null"
alias so_os_admin="pushd ~/devstack >/dev/null && source openrc admin admin && popd >/dev/null"
alias so_euc="pushd ~/devstack >/dev/null && source eucarc && popd >/dev/null"
alias inst="sudo apt-get -y install"
alias remove="sudo apt-get -y remove"
alias u="upcs -cpublic"

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
