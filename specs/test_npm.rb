# frozen_string_literal: true

packages = %w[
  ionic
  cordova
  vmd
  yarn
]

packages.each do |p|
  describe npm(p) do
    it { should be_installed }
  end
end

commands = [
  'cordova -v',
]

commands.each do |c|
  describe command(c) do
    its(:exit_status) { should eq 0 }
  end
end
