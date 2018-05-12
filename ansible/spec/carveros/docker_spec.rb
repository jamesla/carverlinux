require 'spec_helper'

describe package('docker-ce') do
  it { should be_installed.by(:apt) }
end

describe user('vagrant') do
  it { should belong_to_group 'docker' }
end

describe bridge('docker0') do
  it { should exist }
end

describe interface('docker0') do
  it { should have_ipv4_address('192.168.99.5') }
end
