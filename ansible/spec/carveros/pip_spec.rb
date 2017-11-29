require 'spec_helper'

packages = %w[
  python-vagrant
  netaddr
  molecule
  python-openstackclient
]

packages.each do |p|
  describe package(p) do
    it { should be_installed.by(:pip) }
  end
end

commands = [
  'molecule --version'
]

commands.each do |c|
  describe command(c) do
    its(:exit_status) { should eq 0 }
  end
end
