# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "jamesla/ubuntu-1604-min-daily"
  config.vm.hostname = "carveros"
  memory = 8096
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
      config.vm.provision "shell", privileged: false, inline: <<-SHELL
        rm "/home/vagrant/#{f}" || true
      SHELL
      config.vm.provision "file", source: "#{Dir.home}/#{f}", destination: "~/#{f}"
    end
  end

  config.ssh.forward_agent = true

  config.vm.provider "parallels" do |prl|
    prl.name = config.vm.hostname
    prl.memory = memory
    prl.cpus = cpus
    prl.update_guest_tools = true

    prl.customize ["set", :id, "--startup-view=fullscreen"]
    prl.customize ["set", :id, "--device-set=net0", "--adapter-type=e1000"]
    prl.customize ["set", :id, "--nested-virt", "on"]
    prl.customize ["set", :id, "--videosize", "64"]
    prl.customize ["set", :id, "--device-set=hdd0", "--size=150G", "--no-fs-resize" ]
  end

  config.vm.provider "vmware_workstation" do |vmware|
    vmware.gui = true
    vmware.vmx["memsize"] = memory
    vmware.linked_clone = false
    vmware.vmx["numvcpus"] = cpus
    vmware.vmx['vhv.enable'] = 'TRUE'
    vmware.vmx['vhv.allow'] = 'TRUE'
    vmware.vmx["ethernet0.pcislotnumber"] = "33"
    vmware.vmx['ethernet0.virtualDev'] = "e1000"
  end

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    sudo mkdir -p /etc/ansible/roles
    sudo chown vagrant:vagrant /etc/ansible/roles
  SHELL

  config.vm.provision "ansible_local" do |ansible|
    ansible.provisioning_path = "/vagrant/ansible/"
    ansible.verbose = true
    ansible.install = true
    ansible.install_mode = "pip"
    ansible.playbook = "playbook.yml"
    ansible.galaxy_role_file = "requirements.yml"
    ansible.galaxy_roles_path = "/etc/ansible/roles"
    ansible.sudo = true
  end

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    cd /vagrant
    bundle
    rake spec
  SHELL

end
