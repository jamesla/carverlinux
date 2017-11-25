require 'spec_helper'

describe file('/etc/timezone') do
  it { should contain 'Australia/Sydney' }
end

describe command('locale') do
  its(:stdout) { should contain('LANG=en_US.UTF-8') }
end
