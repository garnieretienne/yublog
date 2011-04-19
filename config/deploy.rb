# Requires
require "bundler/capistrano"
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano" 

# Options
set :application, "yublog"
set :ruby, "ruby-1.9.2"
set :scm, :git
set :repository,  "https://github.com/garnieretienne/yublog.git"
set :branch, 'develop'
set :deploy_via, :remote_cache

# Roles
server "95.142.169.122", :app, :web
set :deploy_to, "/var/apps/#{application}"
set :www_user, "www-data"
set :www_group, "www-data"

set :user, 'kurt'
set :use_sudo, true

# RVM and Bundler options
set :rvm_ruby_string, "#{ruby}@#{application}"
set :rvm_type, :user
set :bundle_dir, "" # install gems in the dedicated gemset
set :bundle_flags, "--quiet"

# Rewrite some defauly deployment tasks
namespace:deploy do
  desc "Start the application"
  task :start do
	  sudo("/etc/init.d/#{application} start")
	end
	desc "Stop the application"
	task :stop do
	  sudo("/etc/init.d/#{application} stop")
	end
	desc "Restart the application"
	task :restart do
	  sudo("/etc/init.d/#{application} restart")
	end
	# Clean these tasks
  task :cold do
	  deploy.update
		deploy.start
	end
	# Disable these tasks
	task :migrate do
	end
	task :migrations do
	end
end

# Define shared folder here
namespace :shared do
  # if posts are stored in app/posts
  desc "Store the post folder in shared space"
	task :posts do
	  run("mkdir -p #{deploy_to}/shared/posts")
    run("ln -nfs #{deploy_to}/shared/posts #{deploy_to}/current/")
	end
	# link shared tasks with deploy:update_code
  after "deploy:update_code", "shared:posts"
end

# Define init tasks here
namespace :init do
  # Configure NGiNX
  desc "Create a virtual host for nginx"
	task :nginx, :roles => :web do
	  upload("config/vhost", "/tmp/#{application}")
		sudo("mv /tmp/#{application} /etc/nginx/sites-available/")
		sudo("rm -f /etc/nginx/sites-enabled/#{application}")
		sudo("ln -s /etc/nginx/sites-available/#{application} /etc/nginx/sites-enabled/#{application}")
		sudo("/etc/init.d/nginx restart")
	end
  # Complete deploy:setup
	desc "Give right to app folder and verify git"
	task :setup, :roles => :app do
	  sudo("chown -R #{user}:#{user} #{deploy_to}")
		sudo("apt-get -qy install git-core")
	end
	# RVM configuration
	desc "Create RVM gemset for this application"
	task :rvm, :role => :app do
	  sudo("rvm gemset create #{application}")
		run("echo 'rvm use #{ruby}@#{application} > /dev/null' > #{deploy_to}/.rvmrc")
		run("rvm rvmrc trust #{deploy_to}/.rvmrc")
	end
	# Thin configuration
	desc "Create a thin config and service files"
	task :thin, :role => :app do
	  sudo("mkdir -p /etc/thin/#{application}")
		sudo("mkdir -p /var/log/thin/")
	  sudo("thin -c #{deploy_to}/current -S /tmp/#{application}.sock -l /var/log/thin/#{application}.log -s 1 -C /etc/thin/#{application}/#{application}.yml -e profuction config")
		sudo("thin install")
		sudo("mv /etc/init.d/thin /etc/init.d/#{application}")
		sudo("sudo rvm wrapper #{ruby}@#{application} #{application} thin") # create /usr/local/bin/app_thin
		sudo("sed -i 's/DAEMON=\\/usr\\/bin\\/thin/DAEMON=\\/usr\\/local\\/bin\\/#{application}_thin/g' /etc/init.d/#{application}")
		sudo("sed -i 's/SCRIPT_NAME=\\/etc\\/init.d\\/thin/SCRIPT_NAME=\\/etc\\/init.d\\/#{application}/g' /etc/init.d/#{application}")
		sudo("sed -i 's/CONFIG_PATH=\\/etc\\/thin/CONFIG_PATH=\\/etc\\/thin\\/#{application}/g' /etc/init.d/#{application}")
		sudo("update-rc.d #{application} defaults")
	end
	# link init tasks with deploy:setup
  after "deploy:setup" do
    setup
    nginx
    rvm
    thin
  end
end

