require 'spec_helper'

describe file('/home/vagrant/.gitconfig') do
  it { should be_file }
end

describe file('/home/vagrant/dotfiles') do
  it { should be_directory }
end
