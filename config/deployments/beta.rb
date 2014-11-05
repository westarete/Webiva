set :application, "webiva"
set :scm, :git
set :repository, "git://github.com/westarete/Webiva.git"

set :module_repository, "git://github.com/cykod/"

role :web, "webiva.westarete.com"
role :app, "webiva.westarete.com"
role :db,  "webiva.westarete.com"

set :deploy_to, "/var/www/sites/webiva.beta.westarete.com"

# The remote user to log in as.
set :user, 'deploy'

# Our setup does not require or allow sudo.
set :use_sudo, false

namespace :webiva do
  task :make_public_writeable do
    run "sudo chown -Rh passenger #{deploy.release_path}/public/components"
  end
end
after 'webiva:server_deploy', 'webiva:make_public_writeable'
