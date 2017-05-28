require 'spec_helper'

describe package('virtualbox') do
  it { should be_installed }
end

describe command('vboxmanage -v') do
  its(:exit_status) { should eq 0 }
end
