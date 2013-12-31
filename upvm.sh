#!/bin/bash
set -x
REPOS="openstack-infra/git-review nova heat python-heatclient
       openstack/heat-templates
       keystone openstack-dev/devstack python-keystoneclient
       python-novaclient python-openstackclient
       python-swiftclient swift chmouel/upcs"
PORT_TO_ALLOW="80 8080 5000 35357"
REPO_TO_LINK_HOME="swift devstack python-swiftclient python-keystoneclient keystone"
PIP_PACKAGES="flake8 testrepository coverage tox"
DEB_PACKAGES="libxslt1-dev zlib1g-dev libsqlite3-dev libssl-dev autojump ipython htop build-essential python-dev"

declare -A gists
gists=(
    ["setup-swift-keystone-functional-test.sh"]="5782804 swift-setup-for-keystone-function-test.sh"
    ["ks"]="5001515 ks.sh"
    ["ks3"]="5303094 ks3.py"
    ["ksas"]="4985787 keystone-to-swift-as-another-user.sh"
    ["git-browse"]="5755303 git-browse.sh"
    ["git-jenkins-error"]="8195145 git-jenkins-error.py"
)

set -e

# Enable port
for port in ${PORT_TO_ALLOW};do
    ufw allow ${port}
done

# Update APT
apt-get update --fix-missing

# checkout repos.
mkdir -p /opt/stack
cd /opt/stack
for repo in $REPOS;do
    [[ ${repo} == */* ]] || repo=openstack/${repo}
    [[ -d $(basename ${repo}) ]] || \
        git clone --depth 100 http://github.com/${repo}.git
done

# Install pip
apt-get -y install python-pip

# Install dev tools
apt-get -y install ${DEB_PACKAGES}

# PIP installage.
for i in ${PIP_PACKAGES};do
     pip install --upgrade ${i}
done

cat <<EOF > ~stack/.ssh/config
Host *
    ForwardAgent yes
    GSSAPIAuthentication no
    VerifyHostKeyDNS no
    StrictHostKeyChecking no
    HashKnownHosts no
    TCPKeepAlive yes
    ServerAliveInterval 6000
EOF
cp ~stack/.ssh/config /root/.ssh/config
chown -R stack: ~stack/.ssh/

mkdir -p ~stack/bin
for gist in ${!gists[@]};do
    value=${gists["$gist"]}
    repo=${value/ *}
    binary=${value#* }
    [[ -d ~stack/GIT/${gist} ]] && continue
    git clone http://gist.github.com/${repo}.git ~stack/GIT/${gist}
    ln -sf ~stack/GIT/${gist}/${binary} ~stack/bin/${gist}
    chmod +x ~stack/bin/${gist}
done

# Install upcs.
[[ -e ~stack/GIT/upcs/upcs ]] && ln -sf ~stack/GIT/upcs/upcs ~/bin/upcs

# Install git-review
[[ -e /opt/stack/git-review ]] && { cd /opt/stack/git-review; pip install -e .  ;}

mkdir -p ~stack/.config/rackspace-cloud/
cat <<EOF>~stack/.config/rackspace-cloud/config
RCLOUD_API_USER=\${UK_RCLOUD_USER}
RCLOUD_API_KEY=\${UK_RCLOUD_KEY}
AUTH_SERVER=\${UK_RCLOUD_AURL}
EOF


# Link some repos home.
for i in ${REPO_TO_LINK_HOME};do
    ln -fs /opt/stack/${i} ~stack/${i}
done

# Set my GIT commit as my enovance work email.
git config -f ~stack/.gitconfig user.email chmouel@enovance.com

# Chown it for sure
chown -R stack: ~stack /opt/stack
