# frozen_string_literal: true

describe command('packer -v') do
  its(:exit_status) { should eq 0 }
end
