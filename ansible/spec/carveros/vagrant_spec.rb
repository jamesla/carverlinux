require 'spec_helper'

describe package('vagrant') do
  it { should be_installed }
end

describe command('vagrant -v') do
  its(:exit_status) { should eq 0 }
end

describe package('cpu-checker') do
  it { should be_installed }
end

describe command('kvm-ok') do
  its(:stdout) { should contain('KVM acceleration can be used') }
end
