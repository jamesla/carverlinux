require_relative 'spec_helper'

describe user('vagrant') do
  it { should belong_to_group 'kvm' }
end
