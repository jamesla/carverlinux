# frozen_string_literal: true

describe package('fish') do
  it { should be_installed }
end

describe user('vagrant') do
  its('shell') { should eq '/usr/bin/fish' }
end

describe file('/home/vagrant/.config/fish/config.fish') do
  it { should exist }
end

describe file('/home/vagrant/.config/fish/functions/fish_prompt.fish') do
  it { should exist }
end

describe command('sudo su - vagrant fish -c \'fisher --version\'') do
  its(:exit_status) { should eq 0 }
end

describe command('sudo su - vagrant fish -c \'fisher ls\'') do
  its(:stdout) { should include 'evanlucas/fish-kubectl-completions' }
end
