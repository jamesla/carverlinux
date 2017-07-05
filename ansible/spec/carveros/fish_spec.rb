require 'spec_helper'

describe package('fish') do
  it { should be_installed }
end

describe package('fish') do
  it { should be_installed }
end

describe user('vagrant') do
  it { should have_login_shell '/usr/bin/fish' }
end

describe file('/home/vagrant/.config/fish/config.fish') do
  it { should be_symlink }
end
