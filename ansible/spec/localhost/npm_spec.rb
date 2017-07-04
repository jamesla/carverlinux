require 'spec_helper'

describe package('ionic') do
  it { should be_installed.by(:npm) }
end

describe command('ionic -v') do
  its(:exit_status) { should eq 0 }
end

describe package('yo') do
  it { should be_installed.by(:npm) }
end

describe command('yo --version') do
  its(:exit_status) { should eq 0 }
end

describe package('generator-ansible') do
  it { should be_installed.by(:npm) }
end

describe package('cordova') do
  it { should be_installed.by(:npm) }
end

describe command('cordova -v') do
  its(:exit_status) { should eq 0 }
end

describe package('ionic') do
  it { should be_installed.by(:npm) }
end

describe command('ionic -v') do
  its(:exit_status) { should eq 0 }
end

describe package('grunt-cli') do
  it { should be_installed.by(:npm) }
end

describe package('grunt') do
  it { should be_installed.by(:npm) }
end

describe command('grunt --version') do
  its(:exit_status) { should eq 0 }
end

describe package('bower') do
  it { should be_installed.by(:npm) }
end

describe command('bower -v') do
  its(:exit_status) { should eq 0 }
end

describe package('gulp') do
  it { should be_installed.by(:npm) }
end

describe command('gulp --version') do
  its(:exit_status) { should eq 0 }
end
