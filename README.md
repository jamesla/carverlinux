# Carverlinux

## Quick start

### OSX (Parallels)

1. Install Parallels (http://www.parallels.com)
2. Install Vagrant (https://www.vagrantup.com)
2. Install Parallels Vagrant Plugin (https://github.com/Parallels/vagrant-parallels)

```
mkdir carverlinux && carverlinux
vagrant init jamesla/carverlinux
vagrant up
```

### Windows (Vmware Workstation)

1. Install Vmware Workstation (https://www.vmware.com/go/downloadworkstation)
2. Install Vagrant (https://www.vagrantup.com)
3. Install Vmware Workstation Vagrant Plugin (https://www.vagrantup.com/vmware/index.html) and install license

```
mkdir carverlinux && carverlinux
vagrant init jamesla/carverlinux
vagrant up --provider vmware_workstation

```

### Linux (Libvirt)

1. Install KVM (https://www.linux-kvm.org/page/Main_Page)
2. Install Vagrant (https://www.vagrantup.com)
3. Install Libvirt Vagrant Plugin (https://github.com/vagrant-libvirt/vagrant-libvirt)

```
mkdir carverlinux && carverlinux
vagrant init jamesla/carverlinux
vagrant up --provider libvirt
```
