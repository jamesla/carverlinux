require 'spec_helper'

describe package('docker-ce') do
  it { should be_installed.by(:apt) }
end

describe user('vagrant') do
  it { should belong_to_group 'docker' }
end
