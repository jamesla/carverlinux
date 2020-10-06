# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
control 'usertests' do
  [
    'cordova --version',
    'kubectl --help',
    'java --version',
    'gulp --version',
    'grunt --version',
    'yarn',
    'gcc --version',
    'google-chrome --version',
    'docker version',
    'oc version',
    'istioctl --help',
    'minikube version',
    'helm version',
    'gcloud --version',
    'snap --help',
    'speedtest -h',
    'wget --help',
    'nmap --version',
    'tree --version',
    'aria2c --version',
    'unzip --help',
    'curl --help',
    'git --help',
    'jq --help',
    'whois --version',
    'dig -v',
    'sqlite3 --version',
    'virt-manager --version',
    'fisher ls',
    'dotnet --version',
    'npm -v',
    'molecule',
    'gem -v',
    'rspec --version',
    'rubocop --version',
    'rails -v',
    'ruby -v',
    'python -v',
    'brew -v',
    'pip -v',
    'dmenu -v',
    'nvim --version',
    'tmux -V',
    'ag --version',
    'which tern',
    'emacs --version',
    'kvm --version',
    'virt-manager --version',
    'packer version',
    'terraform version',
    'vagrant -v',
    'inspec --version',
    'aws help'
  ].each do |c|
    describe command("sudo su - vagrant fish -c '#{c}'") do
      its(:exit_status) { should eq 0 }
    end
  end
end
# rubocop:enable Metrics/BlockLength

control 'docker' do
  describe user('vagrant') do
    its('groups') { should include 'docker' }
  end

  describe bridge('docker0') do
    it { should exist }
  end
end

# fish specific
control 'fish' do
  describe user('vagrant') do
    its('shell') { should eq '/usr/bin/fish' }
  end

  describe file('/home/vagrant/.config/fish/config.fish') do
    it { should exist }
  end

  describe file('/home/vagrant/.config/fish/functions/fish_prompt.fish') do
    it { should exist }
  end
end

control 'fish' do
  describe user('vagrant') do
    its('groups') { should include 'kvm' }
  end
end

control 'desktop' do
  describe service('nodm') do
    it { should be_enabled }
  end

  describe file('/etc/X11/Xsession') do
    it { should exist }
    its(:content) { should include 'compton &' }
  end
end

control 'spacemacs' do
  describe file('/home/vagrant/.emacs.d') do
    it { should be_directory }
  end

  describe file('/home/vagrant/.spacemacs') do
    it { should be_exist }
  end
end

control 'timezone' do
  describe file('/etc/timezone') do
    its(:content) { should include 'Australia/Sydney' }
  end
end

control 'tmux' do
  describe file('/home/vagrant/.tmux.conf') do
    it { should exist }
  end

  describe command('whoami') do
    its(:stdout) { should match 'vagrant' }
  end
end
