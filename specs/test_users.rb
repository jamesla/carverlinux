# frozen_string_literal: true

describe command('whoami') do
  its(:stdout) { should match 'vagrant' }
end
