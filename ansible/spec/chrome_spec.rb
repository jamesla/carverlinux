require 'spec_helper'

describe package('google-chrome') do
  it { should be_installed }
end

describe command('google-chrome --version') do
  its(:exit_status) { should eq 0 }
end
