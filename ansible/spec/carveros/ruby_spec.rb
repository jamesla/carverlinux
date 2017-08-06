require 'spec_helper'
packages = %w[
  cfn-flow
  sfn
  rspec
  serverspec
  rubocop
  stack_master
]

packages.each do |p|
  describe package(p) do
    it { should be_installed.by(:gem) }
  end
end

commands = [
  'gem -v',
  'cfn-flow --version',
  'sfn --version',
  'rspec --version',
  'rubocop --version',
  'rails -v'
]

commands.each do |c|
  describe command(c) do
    its(:exit_status) { should eq 0 }
  end
end

# Don't use system ruby
describe command('ruby -v') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should_not contain('system') }
end
