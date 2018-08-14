describe package('docker-ce') do
  it { should be_installed }
end

describe users('vagrant') do
  its('group') { should eq 'docker' }
end

describe bridge('docker0') do
  it { should exist }
end
