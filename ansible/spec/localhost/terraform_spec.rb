require 'spec_helper'

describe command('terraform -v') do
  its(:exit_status) { should eq 0 }
end
