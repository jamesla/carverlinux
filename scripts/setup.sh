#!/bin/bash -eux
set -e

# Add vagrant user to sudoers.
echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# Installing vagrant keys
mkdir ~/.ssh
chmod 700 ~/.ssh
cd ~/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chmod 600 ~/.ssh/authorized_keys
chown -R vagrant ~/.ssh

# Install ansible
pip install ansible

# Install tools
HOME_DIR="${HOME_DIR:-/home/vagrant}";

# Install qemu-tools
case "$PACKER_BUILDER_TYPE" in
   	qemu)
       	apt-get install -y qemu-guest-agent;
        ;;
esac

# Install vmware-open-tools
case "$PACKER_BUILDER_TYPE" in
   	vmware-iso)
       		apt-get install -y open-vm-tools;
		mkdir /mnt/hgfs
		;;
esac

# Install parallel tools
case "$PACKER_BUILDER_TYPE" in
    parallels-iso|parallels-pvm)
        mkdir -p /tmp/parallels;
        mount -o loop $HOME_DIR/prl-tools-lin.iso /tmp/parallels;
        VER="`cat /tmp/parallels/version`";

        echo "Parallels Tools Version: $VER";

        /tmp/parallels/install --install-unattended-with-deps \
            || (code="$?"; \
                echo "Parallels tools installation exited $code, attempting" \
                     "to output /var/log/parallels-tools-install.log"; \
                cat /var/log/parallels-tools-install.log; \
                exit $code);
        umount /tmp/parallels;
        rm -rf /tmp/parallels;
        rm -f $HOME_DIR/*.iso;
        ;;
esac
# Add `sync` so Packer doesn't quit too early
sync
