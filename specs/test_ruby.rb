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
  cfn-flow
  sfn
  rspec
  serverspec
  rubocop
  stack_master
  rails
  sqlite3
]

gems.each do |p|
  describe gem(p) do
    it { should be_installed }
  end
end

commands = [
  'gem -v',
  'cfn-flow --version',
  'sfn --version',
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
