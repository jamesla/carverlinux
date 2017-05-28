require 'spec_helper'

describe package('docker') do
  it { should be_installed }
end

describe command('docker -v') do
  its(:exit_status) { should eq 0 }
end
