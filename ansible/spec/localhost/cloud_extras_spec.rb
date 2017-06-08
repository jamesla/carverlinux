require 'spec_helper'

describe package('docker-compose') do
  it { should be_installed.by(:pip) }
end

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

describe package('azure-cli') do
  it { should be_installed.by(:npm) }
end

describe package('molecule') do
  it { should be_installed.by(:pip) }
end

describe command('molecule --version') do
  its(:exit_status) { should eq 0 }
end

describe package('python-vagrant') do
  it { should be_installed.by(:pip) }
end

# describe package('cfn-flow') do
#   let(:path) { '~/.rvm/gems/ruby-2.4.1/wrappers:$PATH' }
#   it { should be_installed.by(:gem) }
# end

# describe command('cfn-flow --version') do
#   let(:path) { '~/.rvm/gems/ruby-2.4.1/wrappers:$PATH' }
#   its(:exit_status) { should eq 0 }
# end

describe package('cpu-checker') do
  it { should be_installed }
end

describe command('kvm-ok') do
  its(:stdout) { should contain('KVM acceleration can be used') }
end
