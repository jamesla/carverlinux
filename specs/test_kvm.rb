describe user('vagrant') do
  its('groups') { should include 'kvm' }
end
