# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = '2'.freeze

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'jamesla/carverlinux'
  config.vm.hostname = 'carverlinux'
  memory = 4_000
  cpus = 2

  config.cache.scope = 'machine' if Vagrant.has_plugin?('vagrant-cachier')

  files = [
    '.ssh/id_rsa',
    '.ssh/config',
    '.gitconfig'
  ]

  files.each do |f|
    next unless File.file?("#{Dir.home}/#{f}")
    # Remove old file
    config.vm.provision 'shell', privileged: false, inline: <<-SHELL
        rm "/home/vagrant/#{f}" || true
    SHELL

    # Copy new file
    config.vm.provision 'file', source: "#{Dir.home}/#{f}", destination: "~/#{f}"

    # Set id_rsa 600 perms
    if f == '.ssh/id_rsa'
      config.vm.provision 'shell', privileged: false, inline: 'chmod 600 ~/.ssh/id_rsa'
    end
  end

  config.vm.provider 'parallels' do |prl|
    prl.name = config.vm.hostname
    prl.memory = memory
    prl.cpus = cpus
    prl.update_guest_tools = true

    prl.customize ['set', :id, '--startup-view=fullscreen']
    prl.customize ['set', :id, '--device-set=net0', '--adapter-type=e1000']
    prl.customize ['set', :id, '--nested-virt', 'on']
    prl.customize ['set', :id, '--videosize', '64']
  end

  config.vm.provider 'vmware_desktop' do |vmware|
    vmware.gui = true
    vmware.vmx['memsize'] = memory
    vmware.linked_clone = false
    vmware.vmx['numvcpus'] = cpus
    vmware.vmx['vhv.enable'] = 'TRUE'
    vmware.vmx['vhv.allow'] = 'TRUE'
    vmware.vmx['ethernet0.pcislotnumber'] = '33'
    vmware.vmx['ethernet0.virtualDev'] = 'e1000'
  end

  config.vm.provider 'virtualbox' do |vb|
    vb.memory = memory
    vb.cpus = cpus
    vb.gui = true
    vb.name = "carver"
    vb.linked_clone = false
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
    vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
    vb.customize ["modifyvm", :id, "--vram", "128"]
    vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
    vb.customize ["modifyvm", :id, "--bioslogodisplaytime", "0"]
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vb.customize ["modifyvm", :id, "--vrde", "off"]
  end

  config.vm.provider 'libvirt' do |libvirt|
    libvirt.memory = memory
    libvirt.cpus = cpus
    libvirt.nested = 'TRUE'
    libvirt.disk_bus = 'sata'
    libvirt.nic_model_type = 'e1000'
  end
end
