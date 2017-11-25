require 'spec_helper'

describe package('xmonad') do
  it { should be_installed }
end

describe package('suckless-tools') do
  it { should be_installed }
end

describe command('dmenu -v') do
  its(:exit_status) { should eq 0 }
end
