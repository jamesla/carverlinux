describe users('vagrant') do
  its('group') { should eq 'kvm' }
end
