require_relative 'spec_helper'

describe package('xmonad') do
  it { should be_installed }
end

describe package('dmenu') do
  it { should be_installed }
end
