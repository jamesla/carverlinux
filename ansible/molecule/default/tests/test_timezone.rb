describe file('/etc/timezone') do
  its(:stdout) { should include 'Australia/Sydney' }
end

describe command('locale') do
  its(:stdout) { should include 'LC_ALL=en_US.UTF-8' }
end
