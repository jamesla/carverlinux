# frozen_string_literal: true

describe package('docker-ce') do
  it { should be_installed }
end

describe user('vagrant') do
  its('groups') { should include 'docker' }
end

describe bridge('docker0') do
  it { should exist }
end
