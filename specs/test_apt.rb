# frozen_string_literal: true

packages = %w[
  nuget
  telnet
  speedtest-cli
  wget
  nmap
  tree
  aria2
  unzip
  snapd
  curl
  git
  jq
  whois
  dnsutils
  net-tools
  qemu-kvm
  libvirt-dev
  libvirt-bin
  virtinst
  bridge-utils
  p7zip-full
  virt-manager
  ifupdown
]

packages.each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

commands = [
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
  'virt-manager --version'
]

commands.each do |c|
  describe command(c) do
    its(:exit_status) { should eq 0 }
  end
end
