require 'spec_helper'

describe package('powershell') do
  it { should be_installed }
end

describe command('pwsh -v') do
  its(:exit_status) { should eq 0 }
end
