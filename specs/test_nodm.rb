# frozen_string_literal: true

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
end
