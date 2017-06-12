require 'spec_helper'

describe file('/home') do
  it { should be_mounted.with( :device => '/dev/sdc' ) }
end
