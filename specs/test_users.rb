describe command('whoami') do
  its(:stdout) { should match 'vagrant' }
end
