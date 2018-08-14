describe package('virtualbox-5.2') do
  it { should be_installed }
end

describe command('vboxmanage -v') do
  its(:exit_status) { should eq 0 }
end

describe package('cpu-checker') do
  it { should be_installed }
end

describe command('sudo kvm-ok') do
  its(:stdout) { should include('KVM acceleration can be used') }
end
