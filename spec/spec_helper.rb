require 'serverspec'

set :backend, :exec
set :disable_sudo, true
set :path, '/usr/bin:$PATH'
