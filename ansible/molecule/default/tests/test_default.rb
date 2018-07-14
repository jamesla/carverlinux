# Molecule managed

describe file('/etc/hostname') do
  it { should exist }
end

describe user('root') do
  it { should have_uid 0 }
end

describe user('root') do
  it { should have_home_directory '/root' }
end

describe file('/etc/localtime') do
  it { should be_symlink }
  it { should be_linked_to '/usr/share/zoneinfo/Australia/Sydney' }
end

describe file('/etc/securetty') do
  its('content') { should match 'console' }
  its('content') { should match 'tty1' }
  its('content') { should match 'tty2' }
  its('content') { should match 'xvc0' }
  its('content') { should match 'hvc0' }
end

describe package('git') do
  it { should be_installed }
end

describe package('deltarpm') do
  it { should be_installed }
end

describe package('ksh') do
  it { should be_installed }
end

describe package('dos2unix') do
  it { should be_installed }
end

describe package('cronie') do
  it { should be_installed }
end

describe package('rsyslog') do
  it { should be_installed }
end

describe package('sudo') do
  it { should be_installed }
end

describe package('setools-console') do
  it { should be_installed }
end

describe package('telnet') do
  it { should be_installed }
end

describe package('chrony') do
  it { should be_installed }
end

describe package('postfix') do
  it { should be_installed }
end

describe file('/etc/issue') do
  it { should exist }
end

describe file('/etc/audit/rules.d/audit.rules') do
  it { should exist }
end

describe service('sshd') do
  it { should be_enabled }
end

describe service('auditd') do
  it { should be_enabled }
end

describe service('crond') do
  it { should be_enabled }
end

describe service('rsyslog') do
  it { should be_enabled }
end

describe service('chronyd') do
  it { should be_enabled }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'PermitRootLogin no' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'HostbasedAuthentication no' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'PermitEmptyPasswords no' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'X11Forwarding yes' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'X11UseLocalhost yes' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'UsePAM yes' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'Banner /etc/issue' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'KerberosAuthentication yes' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'KerberosTicketCleanup yes' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'GSSAPIAuthentication yes' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'GSSAPICleanupCredentials yes' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'ChallengeResponseAuthentication yes' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match 'Protocol 2' }
end

describe file('/etc/selinux/config') do
  its(:content) { should match 'SELINUX=enforcing' }
end

describe file('/etc/selinux/config') do
  its(:content) { should match 'SELINUXTYPE=targeted' }
end
