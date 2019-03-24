describe package('cabal-install') do
  it { should be_installed }
end

describe package('suckless-tools') do
  it { should be_installed }
end

describe command('dmenu -v') do
  its(:exit_status) { should eq 0 }
end

describe file('/usr/bin/xmonad') do
  it { should exist }
  it { should_be executable }
end
