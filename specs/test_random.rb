# frozen_string_literal: true

files = %w[
  /usr/local/bin/oc
  /usr/local/bin/minishift
  /usr/local/bin/istioctl
  /usr/local/bin/glooctl
]

files.each do |f|
  describe file(f) do
    it { should exist }
    it { should be_executable }
  end
end

commands = [
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

# related to the bug in random ansible playbook
describe file('/usr') do
  it { should be_owned_by 'root' }
  its('group') { should eq 'root' }
  it { should be_directory }
end
