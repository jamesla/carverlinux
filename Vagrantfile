# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "wholebits/ubuntu17.04-64"
  config.vbguest.auto_update = true
  config.vm.hostname = "carveros"

  config.vm.synced_folder ".", "/vagrant", group: 'vagrant', owner: 'vagrant', mount_options: ['share', 'nosuid']

  config.vm.provision "file", source: "~/.gitconfig", destination: ".gitconfig"

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
   rm ~/.ssh/id_rsa || true
  SHELL

  config.vm.provision "file", source: "~/.ssh/id_rsa", destination: "~/.ssh/id_rsa"

  config.ssh.forward_agent = true

  config.vm.provider "parallels" do |prl|
    prl.name = "carveros"
    prl.memory = 16000
    prl.cpus = 4
    prl.update_guest_tools = true

    prl.customize ["set", :id, "--startup-view=fullscreen"]
    prl.customize ["set", :id, "--device-set=net0", "--adapter-type=e1000"]
    prl.customize ["set", :id, "--nested-virt", "on"]
    prl.customize ["set", :id, "--videosize", "64"]

    disk_exists = system("bash -c 'if ! [[ $(prlctl list --info carveros | grep hdd2 | wc -c) -ne 0 ]]; then exit 1; fi'")

    unless disk_exists
      prl.customize ["set", :id, "--device-add", "hdd", "--size=125G"]
    end
      
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
