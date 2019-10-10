#!/bin/bash -eux
set -e

# Install tools
HOME_DIR="${HOME_DIR:-/home/vagrant}"

# Install qemu-tools
case "$PACKER_BUILDER_TYPE" in
qemu)
    apt-get install -y qemu-guest-agent

    # This will ensure the network device is named eth0.
    # https://github.com/vagrant-libvirt/vagrant-libvirt/issues/899
    sed -i -e 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"$/GRUB_CMDLINE_LINUX_DEFAULT="\1 net.ifnames=0"/g' /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg

    # NOTE: the EOF below indenting must be left aligned
    cat <<-EOF >/etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
      dhcp6: false
EOF
    ;;

esac

# Install vmware-open-tools
case "$PACKER_BUILDER_TYPE" in
vmware-iso)
    apt-get install -y open-vm-tools
    mkdir /mnt/hgfs
    ;;
esac

# Install parallel tools
case "$PACKER_BUILDER_TYPE" in
parallels-iso | parallels-pvm)
    mkdir -p /tmp/parallels
    mount -o loop $HOME_DIR/prl-tools-lin.iso /tmp/parallels
    VER="$(cat /tmp/parallels/version)"

    echo "Parallels Tools Version: $VER"

    /tmp/parallels/install --install-unattended-with-deps ||
        (
            code="$?"
            echo "Parallels tools installation exited $code, attempting" \
                "to output /var/log/parallels-tools-install.log"
            cat /var/log/parallels-tools-install.log
            exit $code
        )
    umount /tmp/parallels
    rm -rf /tmp/parallels
    rm -f $HOME_DIR/*.iso
    ;;
esac

# Install virtualbox tools
case "$PACKER_BUILDER_TYPE" in
virtualbox-iso | virtualbox-ovf)
    VER="$(cat /home/vagrant/.vbox_version)"
    ISO="VBoxGuestAdditions_$VER.iso"
    mkdir -p /tmp/vbox
    mount -o loop $HOME_DIR/$ISO /tmp/vbox
    sh /tmp/vbox/VBoxLinuxAdditions.run ||
        echo "VBoxLinuxAdditions.run exited $? and is suppressed." \
            "For more read https://www.virtualbox.org/ticket/12479"
    umount /tmp/vbox
    rm -rf /tmp/vbox
    rm -f $HOME_DIR/*.iso
    ;;
esac

# Add `sync` so Packer doesn't quit too early
sync
