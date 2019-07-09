# frozen_string_literal: true

describe package('nodejs') do
  it { should be_installed }
end

describe command('npm -v') do
  its(:exit_status) { should eq 0 }
end
