# Carverlinux

## Quick start

### OSX (Parallels)

1. Install Parallels (http://www.parallels.com)
2. Install Parallels Vagrant Plugin (https://github.com/Parallels/vagrant-parallels)

```
mkdir carverlinux && carverlinux
vagrant init jamesla/carverlinux
vagrant up
```

### Windows (Vmware Workstation)

1. Install Vmware Workstation (https://www.vmware.com/go/downloadworkstation)
2. Install Vmware Vagrant Plugin (https://www.vagrantup.com/vmware/index.html)

```
mkdir carverlinux && carverlinux
vagrant init jamesla/carverlinux
vagrant up --provider vmware_desktop

```

### Linux (Libvirt)

1. Install KVM (https://www.linux-kvm.org/page/Main_Page)
2. Install Libvirt Vagrant Plugin (https://github.com/vagrant-libvirt/vagrant-libvirt)

```
mkdir carverlinux && carverlinux
vagrant init jamesla/carverlinux
vagrant up --provider libvirt
```
