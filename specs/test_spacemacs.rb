# frozen_string_literal: true

apt_packages = %w[
  ispell
  xclip
  silversearcher-ag
]

apt_packages.each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

npm_packages = %w[
  tern
  js-yaml
  vmd
]

npm_packages.each do |p|
  describe npm(p) do
    it { should be_installed }
  end
end

describe file('/home/vagrant/.emacs.d') do
  it { should be_directory }
end

describe file('/home/vagrant/.spacemacs') do
  it { should be_exist }
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
