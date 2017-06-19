require 'spec_helper'

describe package('ionic') do
  it { should be_installed.by(:npm) }
end

describe command('ionic -v') do
  its(:exit_status) { should eq 0 }
end

describe package('yo') do
  it { should be_installed.by(:npm) }
end

describe command('yo --version') do
  its(:exit_status) { should eq 0 }
end

describe package('generator-ansible') do
  it { should be_installed.by(:npm) }
end
