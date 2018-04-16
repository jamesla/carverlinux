### Carverlinux

## Quick start

# OSX (Parallels)

* Install Parallels (http://www.parallels.com)
* Install Parallels Vagrant Plugin (https://github.com/Parallels/vagrant-parallels)

```
mkdir carverlinux && carverlinux
vagrant init jamesla/carverlinux
vagrant up
```

# Windows (Vmware Workstation)

* Install Vmware Workstation (https://www.vmware.com/go/downloadworkstation)
* Install Vmware Vagrant Plugin (https://www.vagrantup.com/vmware/index.html)

```
mkdir carverlinux && carverlinux
vagrant init jamesla/carverlinux
vagrant up --provider vmware_desktop

```

# Linux (Libvirt)

* Install KVM (https://www.linux-kvm.org/page/Main_Page)
* Install Libvirt Vagrant Plugin (https://github.com/vagrant-libvirt/vagrant-libvirt)

```
mkdir carverlinux && carverlinux
vagrant init jamesla/carverlinux
vagrant up --provider libvirt
```
