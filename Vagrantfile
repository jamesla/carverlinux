# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.
#
  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "wholebits/ubuntu17.04-64"
  config.vbguest.auto_update = true
  config.vm.hostname = "carveros"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  # config.vm.box_url = "http://domain.com/path/to/above.box"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network :private_network, ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network :public_network

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  config.ssh.forward_agent = true

  config.vm.provider "parallels" do |prl|
    prl.name = "carveros"
    prl.memory = 16000
    prl.cpus = 4
    prl.update_guest_tools = true

    prl.customize ["set", :id, "--startup-view=fullscreen"]
    prl.customize ["set", :id, "--device-set=net0", "--adapter-type=e1000"]
    prl.customize ["set", :id, "--device-set=hdd0", "--size=150G"]
  end

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    sudo mkdir -p /etc/ansible/roles
    sudo chown vagrant:vagrant /etc/ansible/roles
  SHELL

  config.vm.provision "ansible_local" do |ansible|
    ansible.verbose = true
    ansible.install = true
    ansible.install_mode = "pip"
    ansible.playbook = "/vagrant/ansible/site.yml"
    ansible.galaxy_role_file = "/vagrant/ansible/requirements.yml"
    ansible.galaxy_roles_path = "/etc/ansible/roles"
    ansible.sudo = true
  end

end
