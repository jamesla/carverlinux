require 'spec_helper'

describe package('emacs') do
  it { should be_installed }
end

describe package('ispell') do
  it { should be_installed }
end

describe package('xclip') do
  it { should be_installed }
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
