require 'spec_helper'

packages = %w[
  telnet
  speedtest-cli
  wget
  nmap
  tree
  aria2
  unzip
  curl
  virtualbox
  git
  jq
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
  'tree --version',
  'aria2c --version',
  'unzip --help',
  'curl --help',
  'git --help',
  'jq --help'
]

commands.each do |c|
  describe command(c) do
    its(:exit_status) { should eq 0 }
  end
end
