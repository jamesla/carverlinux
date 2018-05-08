# Carverlinux

## Quick start

### OSX (Parallels)

1. Install Parallels (http://www.parallels.com)
2. Install Vagrant (https://www.vagrantup.com)
2. Install Parallels Vagrant Plugin (https://github.com/Parallels/vagrant-parallels)
3. Install Parallels Virtualization SDK (brew cask install parallels-virtualization-sdk)

```
mkdir carverlinux && vagrant init jamesla/carverlinux
vagrant up
```

### Windows (Vmware Workstation)

1. Install Vmware Workstation (https://www.vmware.com/go/downloadworkstation)
2. Install Vagrant (https://www.vagrantup.com)
3. Install Vmware Desktop Vagrant Plugin
```
vagrant plugin install vagrant-vmware-desktop
choco install -y vagrant-vmware-utility
vagrant plugin license vagrant-vmware-desktop ~/license.lic
```

```
mkdir carverlinux && cd carverlinux && vagrant init jamesla/carverlinux
vagrant up --provider vmware_desktop

```

### Linux (Libvirt)

1. Install KVM (https://www.linux-kvm.org/page/Main_Page)
2. Install Vagrant (https://www.vagrantup.com)
3. Install Libvirt Vagrant Plugin (https://github.com/vagrant-libvirt/vagrant-libvirt)

```
mkdir carverlinux && vagrant init jamesla/carverlinux
vagrant up --provider libvirt
```

### Important hotkey bindings

Horizontal split ctrl-b + “
Vertical split ctrl-b + %
Show workspaces ctrl-b + w
New workspace ctrl-b + c
Rename workspace ctrl-b + ,
Application launcher alt+p

Window left ctrl + h
Window right ctrl + l
Window up ctrl + j
Window down ctrl + k

Emacs project browser space - p -t
emacs open file as horizontal split highlight file and -
emacs open file as veritical split highlight file and |
