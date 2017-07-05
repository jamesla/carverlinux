require 'spec_helper'

packages = %w[
  telnet
  speedtest-cli
  wget
  nmap
  awscli
  tree
  aria2
  virtualbox
  unzip
]

packages.each do |p|
  describe package(p) do
    it { should be_installed.by(:apt) }
  end
end

commands = [
  'speedtest --version',
  'wget --help',
  'nmap --version',
  'aws --version',
  'tree --version',
  'aria2c --version',
  'unzip --help',
  'virtualbox --help'
]

commands.each do |c|
  describe command(c) do
    its(:exit_status) { should eq 0 }
  end
end
