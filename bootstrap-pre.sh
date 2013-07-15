#!/bin/bash
set -x
sudo grep -q '^%sudo.* ALL' /etc/sudoers  && sudo sed -i '/^%sudo/ { s/ALL$/NOPASSWD:ALL/}' /etc/sudoers
sudo grep -q '^%admin.* ALL' /etc/sudoers  && sudo sed -i '/^%admin/ { s/ALL$/NOPASSWD:ALL/}' /etc/sudoers
sudo useradd -s /bin/bash -G adm,sudo,dialout,cdrom,floppy,audio,dip,video,plugdev,netdev,admin -m stack
sudo cp -a /home/ubuntu/.ssh /home/stack/
sudo chown -R stack: /home/stack/.ssh
chmod +x /tmp/bootstrap.sh
