require 'spec_helper'

packages = %w[
  emacs
  ispell
  xclip
  tern
  js-yaml
  silversearcher-ag
]

packages.each do |p|
  describe package(p) do
    it { should be_installed.by(:apt) || should be_installed.by(:pip) }
  end
end

describe command('which tern') do
  its(:exit_status) { should eq 0 }
end

describe command('which emacs') do
  its(:exit_status) { should eq 0 }
end

describe file('/home/vagrant/.emacs.d') do
  it { should be_directory }
end

describe file('/home/vagrant/.spacemacs') do
  it { should be_symlink }
end

describe command('ag --version') do
  its(:exit_status) { should eq 0 }
end
