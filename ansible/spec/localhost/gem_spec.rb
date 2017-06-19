require 'spec_helper'

describe package('cfn-flow') do
  it { should be_installed.by(:gem) }
end

describe command('cfn-flow --version') do
  its(:exit_status) { should eq 0 }
end
