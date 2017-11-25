require 'spec_helper'

describe command('consul -v') do
  its(:exit_status) { should eq 0 }
end
