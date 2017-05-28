require_relative 'spec_helper'

describe command('gem -v') do
  its(:exit_status) { should eq 0 }
end

describe command('ruby -v') do
  its(:exit_status) { should eq 0 }
end
