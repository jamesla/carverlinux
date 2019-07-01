# frozen_string_literal: true

describe package('google-chrome-stable') do
  it { should be_installed }
end

describe command('google-chrome --version') do
  its(:exit_status) { should eq 0 }
end
