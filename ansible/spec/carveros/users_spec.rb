require_relative 'spec_helper'

describe command('whoami') do
  its(:stdout) { should match 'vagrant' }
end
