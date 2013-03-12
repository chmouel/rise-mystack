#!/bin/bash
REPOS="ceilometer cinder glance horizon keystone nova python-ceilometerclient python-cinderclient python-glanceclient python-keystoneclient python-novaclient python-openstackclient python-swiftclient swift"
PORT_TO_ALLOW="80 8080 5000 35357"

set -e

# Enable port
for port in ${PORT_TO_ALLOW};do
    ufw allow ${port}
done

# Update APT
apt-get update --fix-missing

# Install scripts from p.chmouel.com
mkdir -p ~stack/bin
cd ~stack/bin
for i in ks restartswift;do
    curl -O http://p.chmouel.com/${i}
done
chmod +x ~stack/bin/*

mkdir -p /opt/stack
cd /opt/stack
for repo in $REPOS;do
    git clone --depth 100 https://github.com/openstack/${repo}.git
done

# Install dev tools
apt-get -y install python-pip ipython htop build-essential

# PIP installage.
for i in tox testrepository coverage git-review flake8;do
     pip install --upgrade ${i}
done

# Checkout
cd ~/GIT
[[ -d upcs ]] || git clone https://github.com/chmouel/upcs.git
ln -sf ~/GIT/upcs/upcs ~/bin

mkdir -p ~stack/.config/rackspace-cloud/
cat <<EOF>~stack/.config/rackspace-cloud/config
RCLOUD_API_USER=\${UK_RCLOUD_USER}
RCLOUD_API_KEY=\${UK_RCLOUD_KEY}
AUTH_SERVER=\${UK_RCLOUD_AURL}
EOF

# Set my GIT commit as my enovance work email.
git config -f ~stack/.gitconfig user.email chmouel@enovance.com

[[ -d ~/devstack ]] || git clone https://github.com/openstack-dev/devstack.git ~/devstack

# Chown it for sure
chown -R stack: ~stack /opt/stack
