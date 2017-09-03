require 'spec_helper'

apt_packages = %w[
  emacs
  ispell
  xclip
  silversearcher-ag
]

apt_packages.each do |p|
  describe package(p) do
    it { should be_installed.by(:apt) }
  end
end

npm_packages = %w[
  tern
  js-yaml
  vmd
]

npm_packages.each do |p|
  describe package(p) do
    it { should be_installed.by(:npm) }
  end
end

describe file('/home/vagrant/.emacs.d') do
  it { should be_directory }
end

describe file('/home/vagrant/.spacemacs') do
  it { should be_symlink }
end

commands = [
  'ag --version',
  'which tern',
  'emacs --version'
]

commands.each do |c|
  describe command(c) do
    its(:exit_status) { should eq 0 }
  end
end