require 'spec_helper'

describe command('lsblk') do
  its(:stdout) { should match /150G/ }
end
