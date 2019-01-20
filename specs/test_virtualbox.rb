describe package('virtualbox-6.0') do
  it { should be_installed }
end

describe command('vboxmanage -v') do
  its(:exit_status) { should eq 0 }
end

describe package('cpu-checker') do
  it { should be_installed }
end
