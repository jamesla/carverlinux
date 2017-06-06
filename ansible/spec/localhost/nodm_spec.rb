require 'spec_helper'

describe package('libxft-dev') do
  it { should be_installed }
end
describe package('xinit') do
  it { should be_installed }
end

describe package('nodm') do
  it { should be_installed }
end

describe service('nodm') do
  it { should be_enabled }
  # it { should be_running }
end
