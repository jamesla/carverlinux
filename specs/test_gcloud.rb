# frozen_string_literal: true

describe package('google-cloud-sdk') do
  it { should be_installed }
end

describe command('gcloud --version') do
  its(:exit_status) { should eq 0 }
end
