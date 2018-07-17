describe package('docker-ce') do
  it { should be_installed }
end

describe user('vagrant') do
  its('group') { should eq 'docker' }
end

describe bridge('docker0') do
  it { should exist }
end

# describe interface('docker0') do
  # it { should have_ipv4_address('192.168.99.5') }
# end
