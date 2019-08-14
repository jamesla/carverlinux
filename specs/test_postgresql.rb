# frozen_string_literal: true

%w[
  postgresql
  libpq-dev
].each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

describe service('postgresql@10-main') do
  it { should be_enabled }
  it { should be_installed }
end

describe user('postgres') do
  it { should exist }
end
