require 'spec_helper'

describe package('consul') do
  it { should be_installed }
end

describe command('consul -v') do
  its(:exit_status) { should eq 0 }
end
