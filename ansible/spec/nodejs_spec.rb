require_relative 'spec_helper'

describe package('nodejs') do
  it { should be_installed }
end

describe package('nodejs-legacy') do
  it { should be_installed }
end

describe package('npm') do
  it { should be_installed }
end
