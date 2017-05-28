require 'spec_helper'

describe package('packer') do
  it { should be_installed }
end

describe command('packer -v') do
  its(:exit_status) { should eq 0 }
end
