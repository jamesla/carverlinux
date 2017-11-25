require 'spec_helper'

describe file('/usr/bin/tmux') do
  it { should exist }
end

describe file('/home/vagrant/.tmux.conf') do
  it { should exist }
end

describe command('tmux -V') do
  its(:exit_status) { should eq 0 }
end
