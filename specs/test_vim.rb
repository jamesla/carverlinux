# frozen_string_literal: true

describe file('/home/vagrant/.vimrc') do
  it { should exist }
end

describe file('/home/vagrant/.vim/bundle/Vundle.vim') do
  it { should exist }
end

describe package('vim') do
  it { should be_installed }
end

describe command('vim --version') do
  its(:exit_status) { should eq 0 }
end
