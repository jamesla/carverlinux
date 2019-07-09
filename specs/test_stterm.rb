# frozen_string_literal: true

describe file('/usr/local/bin/st') do
  it { should exist }
end
