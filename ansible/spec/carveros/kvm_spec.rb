require 'spec_helper'

describe user('vagrant') do
  it { should belong_to_group 'libvirtd' }
  it { should belong_to_group 'kvm' }
end
