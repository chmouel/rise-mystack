#!/bin/bash
# sudo apt-get -y install curl  && bash  <(curl http://www.chmouel.com/pub/bootstrap.sh)
export DEB_PACKAGES="vim tmux screen git-core exuberant-ctags  zsh-beta ack-grep"
export RPM_PACKAGES="vim tmux screen git zsh ack yum-cron deltarpm"
export DEBIAN_FRONTEND=noninteractive
set -e

sudo sed -i '/^%\(wheel\|sudo\)/ { s/ALL$/NOPASSWD: ALL/ }' /etc/sudoers

function debianies () {
    version=$(lsb_release -c -s)
    sudo apt-get -y install locales
    sudo locale-gen en_GB.UTF-8
    sudo dpkg-reconfigure locales

    if [[ ${version} == natty || ${version} == oneiric ]];then
        # Old School CS
        sudo sed -i '/^deb.*main/ { /restricted$/ { s/$/ multiverse/; }}' /etc/apt/sources.list
        # New School CS
        sudo sed  -i '/^#deb .*\(multiverse\|universe\)$/ { s/^#//; }' /etc/apt/sources.list
        sudo apt-get update

        sudo sed -i 's/nova.clouds.//g' /etc/apt/sources.list
    fi
    sudo apt-get -y install ${DEB_PACKAGES}
    sudo update-alternatives --set editor /usr/bin/vim.basic

    sudo apt-get -y install ufw && \
        sudo ufw allow proto tcp from any to any port 22 && \
        sudo ufw -f enable
}

function readties() {
    if [[ -z $RHEL_SKIP_REG && -e /usr/bin/subscription-manager ]];then
        if [[ -n ${RHEL_USER} && -n ${RHEL_PASSWORD} ]];then
            sudo subscription-manager register --user ${RHEL_USER} \
                 --password ${RHEL_PASSWORD} || true
        else
            echo "Enter your RHN user/password: "
            sudo subscription-manager register --force || true
        fi
        if [[ -n ${RHEL_POOL} ]];then
            sudo subscription-manager subscribe --pool ${RHEL_POOL}
        else
            sudo subscription-manager attach --auto || true
        fi
    fi

    if [[ -e /etc/yum.conf ]];then
	    sudo sed -i '/\[main\]/a assumeyes=1' /etc/yum.conf
        RPMI=yum
    else
	    RPMI=dnf
        echo "assumeyes=True" | sudo tee -a /etc/dnf/dnf.conf >/dev/null
    fi
    sudo $RPMI -y update
    sudo $RPMI -y install ${RPM_PACKAGES}
}

# Install dev tools
if [[ -e /usr/bin/apt-get ]];then
    debianies
elif [[ -e /usr/bin/yum ]];then
    readties
fi


sudo chsh -s /bin/zsh $USER

cd $HOME
mkdir -p GIT
cd GIT

for repo in rc zsh vim;do
    [[ -d $repo-config ]] && continue
    git clone --recursive http://github.com/chmouel/${repo}-config.git
done

for f in gitconfig gitexclude screenrc tmux.conf;do
    rm -f ~/.${f}
    ln -fs GIT/rc-config/${f} ~/.${f}
done

ln -fs GIT/zsh-config ~/.shell
ln -fs .shell/config/zshrc ~/.zshrc
ln -fs GIT/vim-config ~/.vim

vim +PluginInstall +qall || true

echo -e "#\n#hostColor=\"yellow\"\n#userColor=\"white\"\n" > ~/.shell/hosts/${HOSTNAME%%.*}.sh

cat <<EOF>~/.shell/hosts/${HOSTNAME%%.*}.sh
# hostColor="yellow"
# userColor="white"

alias inst="sudo yum -y install"
alias remove="sudo yum -y remove"
alias g="git grep"

export LESS="-r"
EOF
