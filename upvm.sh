#!/bin/bash
set -e

# Enable port
ufw allow 80

# Update git
for gitdir in ~stack/GIT ~stack;do
    cd ${gitdir}
    for dir in *;do
        [[ -d ${dir}/.git ]] || continue
        pushd $dir >/dev/null
        git pull;
        popd >/dev/null
    done
done

# Update vim submodules
cd ~stack/.vim
git submodule update --init

# Install scripts from p.chmouel.com
mkdir -p ~stack/bin
cd ~stack/bin
for i in ks restartswift;do
    curl -O http://p.chmouel.com/${i}
done
chmod +x ~stack/bin/*

# Install dev tools
apt-get -y install python-pip ipython htop build-essential

# PIP installage.
for i in tox testrepository coverage git-review flake8;do
     pip install --upgrade ${i}
done

# Checkout
cd ~/GIT
git clone https://github.com/chmouel/upcs.git
ln -s ~/GIT/upcs/upcs ~/bin

mkdir -p ~stack/.config/rackspace-cloud/
cat <<EOF>~stack/.config/rackspace-cloud/config
RCLOUD_API_USER=\${UK_RCLOUD_USER}
RCLOUD_API_KEY=\${UK_RCLOUD_KEY}
AUTH_SERVER=\${UK_RCLOUD_AURL}
EOF

chown -R stack: ~stack/GIT /opt/stack
