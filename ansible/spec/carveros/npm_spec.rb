require 'spec_helper'

packages = %w[
  ionic
  yo
  cordova
  grunt-cli
  grunt
  bower
  gulp
]

packages.each do |p|
  describe package(p) do
    it { should be_installed.by(:npm) }
  end
end

commands = [
  'ionic -v',
  'yo --version',
  'cordova -v',
  'grunt --version',
  'ionic -v',
  'bower -v',
  'gulp --version'
]

commands.each do |c|
  describe command(c) do
    its(:exit_status) { should eq 0 }
  end
end
