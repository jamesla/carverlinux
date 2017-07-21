require 'spec_helper'

describe package('virtualbox') do
  it { should be_installed.by(:apt) }
end

describe command('vboxmanage -v') do
  its(:exit_status) { should eq 0 }
end

describe package('cpu-checker') do
  it { should be_installed }
end

describe command('kvm-ok') do
  its(:stdout) { should contain('KVM acceleration can be used') }
end
