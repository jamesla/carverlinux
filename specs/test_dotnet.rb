# frozen_string_literal: true

describe command( 'dotnet --version') do
  its(:exit_status) { should eq 0 }
end
