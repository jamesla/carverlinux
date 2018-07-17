describe user('vagrant') do
  its('group') { should eq 'kvm' }
end
