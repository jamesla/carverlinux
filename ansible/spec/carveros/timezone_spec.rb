require_relative 'spec_helper'

describe file('/etc/timezone') do
  it { should contain 'Australia/Sydney' }
end

describe command('locale') do
  its(:stdout) { should contain 'LC_ALL=en_US.UTF-8' }
end
