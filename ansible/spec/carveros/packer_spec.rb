require_relative 'spec_helper'

describe command('packer -v') do
  its(:exit_status) { should eq 0 }
end
