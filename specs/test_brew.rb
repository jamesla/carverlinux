# frozen_string_literal: true

commands = [
  'oc version',
  'istioctl --help',
  'minikube version',
  'helm version'
]

commands.each do |c|
  describe command("sudo su - vagrant fish -c #{c}") do
    its(:exit_status) { should eq 0 }
  end
end
