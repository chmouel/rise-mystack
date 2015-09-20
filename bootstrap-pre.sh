#!/bin/bash
# Pre bootstrap to get the useradd, sudo and perms working
set -e

if [[ -e /usr/bin/apt-get ]];then
    ORIG_USER=ubuntu
    NEWGROUPS=adm,sudo,dialout,cdrom,floppy,audio,dip,video,plugdev,netdev,admin
elif id cloud-user 2>/dev/null >/dev/null;then
    ORIG_USER=cloud-user
    NEWGROUPS="cloud-user,adm,wheel,systemd-journal"
elif id fedora 2>/dev/null >/dev/null;then
    ORIG_USER=fedora
    NEWGROUPS="fedora,adm,wheel,systemd-journal"
fi

if [[ -e /etc/cloud/cloud.cfg ]];then
    grep -q set_hostname /etc/cloud/cloud.cfg  && sudo sed -i '/set_hostname/d' /etc/cloud/cloud.cfg 
    grep -q update_hostname /etc/cloud/cloud.cfg  && sudo sed -i '/update_hostname/d' /etc/cloud/cloud.cfg 
    grep \.novalocal /etc/hostname && sudo sed -i 's/\.novalocal//' /etc/hostname
    sudo hostname $(</etc/hostname)
fi

set -x
sudo sed -i '/^%\(wheel\|sudo\)/ { s/ALL$/NOPASSWD: ALL/ }' /etc/sudoers

[[ -d /home/stack ]] || {
    sudo useradd -s /bin/bash -G ${NEWGROUPS} -m stack
    sudo cp -a /home/${ORIG_USER}/.ssh /home/stack/
    sudo chown -R stack: /home/stack/.ssh
}
chmod +x /tmp/bootstrap.sh
