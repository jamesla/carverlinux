require 'spec_helper'

describe file('/etc/timezone') do
  it { should be_contain 'Australia/Sydney' }
end
