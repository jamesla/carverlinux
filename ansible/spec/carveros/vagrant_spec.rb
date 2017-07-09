require 'spec_helper'

describe package('vagrant') do
  it { should be_installed }
end

describe command('vagrant -v') do
  its(:exit_status) { should eq 0 }
end
