require 'spec_helper'

describe package('python-vagrant') do
  it { should be_installed.by(:pip) }
end

describe package('netaddr') do
  it { should be_installed.by(:pip) }
end

describe package('docker-compose') do
  it { should be_installed.by(:pip) }
end

describe command('docker-compose --version') do
  its(:exit_status) { should eq 0 }
end

describe package('molecule') do
  it { should be_installed.by(:pip) }
end

describe command('molecule --version') do
  its(:exit_status) { should eq 0 }
end
