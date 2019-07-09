# frozen_string_literal: true

describe user('vagrant') do
  its('groups') { should include 'kvm' }
end
