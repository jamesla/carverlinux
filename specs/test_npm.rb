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
  describe npm(p) do
    it { should be_installed }
  end
end

commands = [
  'yo --version',
  'cordova -v',
  'grunt --version',
  'bower -v',
  'gulp --version'
]

commands.each do |c|
  describe command(c) do
    its(:exit_status) { should eq 0 }
  end
end
