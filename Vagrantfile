# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "jamesla/carverlinux"
  config.vm.hostname = "carverlinux"
  memory = 14000
  cpus = 4

  if Vagrant.has_plugin?('vagrant-cachier')
    config.cache.scope = 'machine'
  end

  files = [
    ".ssh/id_rsa",
    ".ssh/config",
    ".gitconfig"
  ]

  files.each do |f|
    if File.file?("#{Dir.home}/#{f}") then
      # Remove old file
      config.vm.provision "shell", privileged: false, inline: <<-SHELL
        rm "/home/vagrant/#{f}" || true
      SHELL

      # Copy new file
      config.vm.provision "file", source: "#{Dir.home}/#{f}", destination: "~/#{f}"

      # Set id_rsa 600 perms
      if f  == ".ssh/id_rsa"
        config.vm.provision "shell", privileged: false, inline: "chmod 600 ~/.ssh/id_rsa"
      end
    end
  end

  config.vm.provider "parallels" do |prl|
    prl.name = config.vm.hostname
    prl.memory = memory
    prl.cpus = cpus
    prl.update_guest_tools = true

    prl.customize ["set", :id, "--startup-view=fullscreen"]
    prl.customize ["set", :id, "--device-set=net0", "--adapter-type=e1000"]
    prl.customize ["set", :id, "--nested-virt", "on"]
    prl.customize ["set", :id, "--videosize", "64"]
  end

  config.vm.provider "vmware_desktop" do |vmware|
    vmware.gui = true
    vmware.vmx["memsize"] = memory
    vmware.linked_clone = false
    vmware.vmx["numvcpus"] = cpus
    vmware.vmx['vhv.enable'] = 'TRUE'
    vmware.vmx['vhv.allow'] = 'TRUE'
    vmware.vmx["ethernet0.pcislotnumber"] = "33"
    vmware.vmx['ethernet0.virtualDev'] = "e1000"
  end

  config.vm.provider "libvirt" do |libvirt|
    libvirt.memory = memory
    libvirt.cpus = cpus
    libvirt.nested = 'TRUE'
    # libvirt.cpu_mode = 'host-model'
    libvirt.disk_bus = 'sata'
    # libvirt.disk_device = 'sda'
    libvirt.nic_model_type = 'e1000'
  end
end
