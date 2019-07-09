# frozen_string_literal: true

describe file('/usr/local/bin/kubectl') do
  it { should be_file }
  it { should be_executable }
end

describe file('/usr/local/bin/minikube') do
  it { should be_file }
  it { should be_executable }
end
