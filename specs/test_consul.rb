# frozen_string_literal: true

describe command('consul -v') do
  its(:exit_status) { should eq 0 }
end
