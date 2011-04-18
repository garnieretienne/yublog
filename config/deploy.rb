require "bundler/capistrano"

set :application, "yublog"
set :scm, :git
set :repository,  "https://github.com/garnieretienne/yublog.git"
set :branch, 'develop'
set :deploy_via, :remote_cache
set :bundle_flags, "--quiet"

set :user, 'kurt'
set :use_sudo, true

server "95.142.169.122", :app, :web, :db, :primary => true
set :deploy_to, "/var/apps/yublog"
set :www_user, "www-data"
set :www_group, "www-data"


# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

namespace :init do
  desc "Create a virtual host for nginx"
	task :nginx, :roles => :web do
	  upload("config/vhost", "/tmp/#{application}")
		sudo("mv /tmp/#{application} /etc/nginx/sites-available/")
		sudo("ln -s /etc/nginx/sites-available/#{application} /etc/nginx/sites-enabled/#{application}")
		sudo("/etc/init.d/nginx restart")
	end
	desc "Give right to app folder and verify git"
	task :setup, :roles => :app do
	  sudo("chown -R #{user}:#{user} #{deploy_to}")
		sudo("apt-get -qy install git-core")
	end
end
