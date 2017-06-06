require 'spec_helper'

describe package('tmux') do
  it { should be_installed }
end

describe file('/home/vagrant/.tmux.conf') do
  it { should be_symlink }
end
