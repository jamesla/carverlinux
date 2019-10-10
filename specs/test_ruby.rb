# frozen_string_literal: true

apts = %w[
  ruby
  ruby-dev
]

apts.each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

gems = %w[
  rspec
  serverspec
  rubocop
  rails
  sqlite3
  inspec
  inspec-bin
]

# something wrong with inspec gem resource reenable later
# gems.each do |p|
#   describe gem(p) do
#     it { should be_installed }
#   end
# end

commands = [
  'gem -v',
  'rspec --version',
  'rubocop --version',
  'rails -v'
]

commands.each do |c|
  describe command(c) do
    its(:exit_status) { should eq 0 }
  end
end

# Don't use system ruby
describe command('ruby -v') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should_not include('system') }
end
