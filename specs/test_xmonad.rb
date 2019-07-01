# frozen_string_literal: true

%w[
  cabal-install
  suckless-tools
  libxss-dev
  libxrandr-dev
  compton
  feh
  xmonad
].each do |package|
  describe package(package) do
    it { should be_installed }
  end
end

describe command('dmenu -v') do
  its(:exit_status) { should eq 0 }
end

describe file('/etc/X11/Xsession') do
  it { should exist }
  its(:content) { should include 'compton &' }
end
