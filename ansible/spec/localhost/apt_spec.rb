require 'spec_helper'

describe command('docker-compose --version') do
  its(:exit_status) { should eq 0 }
end

describe package('wget') do
  it { should be_installed }
end

describe command('wget -V') do
  its(:exit_status) { should eq 0 }
end

describe package('nmap') do
  it { should be_installed }
end

describe command('nmap --version') do
  its(:exit_status) { should eq 0 }
end

describe package('awscli') do
  it { should be_installed }
end

describe command('aws --version') do
  its(:exit_status) { should eq 0 }
end

describe package('tree') do
  it { should be_installed }
end

describe command('tree --version') do
  its(:exit_status) { should eq 0 }
end

describe package('yo') do
  it { should be_installed.by(:npm) }
end

describe command('yo --version') do
  its(:exit_status) { should eq 0 }
end

describe package('generator-ansible') do
  it { should be_installed.by(:npm) }
end

describe package('cfn-flow') do
  it { should be_installed.by(:gem) }
end

describe command('cfn-flow --version') do
  its(:exit_status) { should eq 0 }
end

describe package('aria2') do
  it { should be_installed }
end

describe command('aria2c -v') do
  its(:exit_status) { should eq 0 }
end

describe package('cpu-checker') do
  it { should be_installed }
end

describe command('kvm-ok') do
  its(:stdout) { should contain('KVM acceleration can be used') }
end

describe package('ionic') do
  it { should be_installed.by(:npm) }
end

describe command('ionic -v') do
  its(:exit_status) { should eq 0 }
end
