# frozen_string_literal: true

describe command('sudo su - vagrant fish -c \'terraform version\'') do
  its(:exit_status) { should eq 0 }
end
