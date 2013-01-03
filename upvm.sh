#!/bin/bash
set -e

mkdir -p ~stack/.config/rackspace-cloud/
cat <<EOF>~stack/.config/rackspace-cloud/config
RCLOUD_API_USER=\${UK_RCLOUD_USER}
RCLOUD_API_KEY=\${UK_RCLOUD_KEY}
AUTH_SERVER=\${UK_RCLOUD_AURL}
EOF

ufw allow 80

for gitdir in ~stack/GIT ~stack;do
    cd ${gitdir}
    for dir in *;do
        [[ -d ${dir}/.git ]] || continue
        pushd $dir >/dev/null
        git pull;
        popd >/dev/null
    done
done

mkdir -p ~stack/.vim/bundle
cd ~stack/.vim/bundle
for a in https://github.com/scrooloose/syntastic.git;do
    i=$(echo "${a##*/}"|sed 's/.git//')
    if [[ -d ~stack/.vim/bundle/$i ]];then
        pushd $i > /dev/null && git pull && popd >/dev/null
    else
        git clone $a
    fi
done

chown -R stack: ~stack/GIT /opt/stack

apt-get -y install python-pip ipython

for i in git-review flake8;do
     pip install -U ${i}
done
