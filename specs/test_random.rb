files = %w(
  /usr/local/bin/oc
  /usr/local/bin/minishift
  /usr/local/bin/istioctl
  /usr/local/bin/glooctl
  /snap/bin/helm
)

files.each do |f|
  describe file(f) do
    it { should exist }
    it { should be_executable }
  end
end

commands = [
  'helm --help',
  'oc version',
  'istioctl --help',
  'glooctl --help',
  'minishift version'
]


commands.each do |c|
  describe command(c) do
    its(:exit_status) { should eq 0 }
  end
end
