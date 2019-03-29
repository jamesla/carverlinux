# Carverlinux


## Differences between versions

Hypervisor | OS | Details
--- | --- | ---
Virtualbox | Cross-platform | Free, Cross-platform, lacks nested virtualisation support*
Parallels | OSX | Requires a [parallels pro license](https://www.parallels.com/products/desktop/pro/#compare) for vagrant support
Vmware Desktop | Windows | Requires a [vagrant vmware license](https://www.vagrantup.com/vmware/index.html)
Libvirt | Linux | Free

\* Nested Virtualisation Support is the processor extensions VT-X or AMD-V which a hypervisor needs to be able to pass to a vm in order to run virtual machines inside virtual machines. If your workflow requires this then you will need to use either the parallels, vmware desktop or libvirt options.

## Quick start

### Virtualbox
```
vagrant up jamesla/carverlinux
```

### Parallels

Install dependencies
```
brew cask install parallels parallels-virtualization-sdk vagrant
vagrant plugin install vagrant-parallels
```

Start box
```
vagrant init jamesla/carverlinux
vagrant up --provider=parallels
```

### Vmware Workstation

Install dependencies
```
choco install -y vmwareworkstation vagrant vagrant-vmware-utility
vagrant plugin install vagrant-vmware-desktop
vagrant plugin license vagrant-vmware-desktop %path_to_your_license_file%
```

Start box
```
vagrant init jamesla/carverlinux
vagrant up --provider vmware_desktop

```

### Libvirt (KVM)

1. Install KVM (https://www.linux-kvm.org/page/Main_Page)
2. Install Vagrant (https://www.vagrantup.com)
3. Install Libvirt Vagrant Plugin (https://github.com/vagrant-libvirt/vagrant-libvirt)

```
vagrant init jamesla/carverlinux
vagrant up --provider libvirt
``

### Important hotkey bindings

* Terminal Horizontal split ctrl-b "
* Terminal Vertical split ctrl-b %
* Show terminal windows ctrl-b w
* New terminal window ctrl-b c
* Rename terminal window ctrl-b
* Kill termainl window ctrl-b &

* Window left ctrl + h
* Window right ctrl + l
* Window up ctrl + j
* Window down ctrl + k

* Emacs project browser space - p -t
* Emacs open file as horizontal split highlight file and -
* Emacs open file as veritical split highlight file and |

* Application launcher alt+p
* Change workspace alt + 1,2,3,4 etc
* Move application to new workspace: alt + shift + number of workspace you want to move it to
