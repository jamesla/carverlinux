require 'spec_helper'

describe package('docker-ce') do
  it { should be_installed.by(:apt) }
end

describe command('docker run hello-world') do
  its(:exit_status) { should eq 0 }
end

describe user('vagrant') do
  it { should belong_to_group 'docker' }
end
