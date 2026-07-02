require 'serverspec'

# Required by serverspec
set :backend, :exec

describe package('epel-release'), :if => os[:family] == 'redhat' do
  it { should be_installed }
end
