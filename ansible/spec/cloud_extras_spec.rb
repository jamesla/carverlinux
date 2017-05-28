require 'spec_helper'

describe package('docker-compose') do
  it { should be_installed }
end

describe command('docker-compose --version') do
  let(:disable_sudo) { true }
  its(:exit_status) { should eq 0 }
end

describe package('wget') do
  it { should be_installed }
end

describe command('wget -V') do
  let(:disable_sudo) { true }
  its(:exit_status) { should eq 0 }
end

describe package('nmap') do
  it { should be_installed }
end

describe command('nmap --version') do
  let(:disable_sudo) { true }
  its(:exit_status) { should eq 0 }
end

describe package('awscli') do
  it { should be_installed }
end

describe command('aws --version') do
  let(:disable_sudo) { true }
  its(:exit_status) { should eq 0 }
end

describe package('tree') do
  it { should be_installed }
end

describe command('tree --version') do
  let(:disable_sudo) { true }
  its(:exit_status) { should eq 0 }
end

describe package('yo') do
  it { should be_installed }
end

describe command('yo --version') do
  let(:disable_sudo) { true }
  its(:exit_status) { should eq 0 }
end

describe package('generator-ansible') do
  it { should be_installed }
end

describe package('azure-cli') do
  it { should be_installed }
end

describe command('azure --version') do
  let(:disable_sudo) { true }
  its(:exit_status) { should eq 0 }
end

describe package('cfn-flow') do
  it { should be_installed }
end

describe command('cfn-flow --version') do
  let(:disable_sudo) { true }
  its(:exit_status) { should eq 0 }
end
