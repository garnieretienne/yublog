# Requires
require "bundler/capistrano"
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano" 

# Options
set :application, "yublog"
set :ruby, "ruby-1.9.2"
set :scm, :git
set :repository,  "https://github.com/garnieretienne/yublog.git"
set :branch, 'kurt.yuweb.fr'
set :deploy_via, :remote_cache
default_run_options[:pty] = true # sometimes needed for some distros

# Roles
server "95.142.169.122", :app, :web
set :deploy_to, "/var/apps/#{application}"
set :www_user, "www-data"
set :www_group, "www-data"

set :user, 'kurt'
set :use_sudo, true

# RVM and Bundler options
set :rvm_ruby_string, "#{ruby}@#{application}"
set :sudo, "PATH=/sbin:/usr/sbin:$PATH && /usr/local/bin/rvmsudo" # bind sudo command with RVM and enable admin commands
set :sudo_prompt, ''
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
  desc "Restore the post folder from shared space in current"
	task :link_posts do
    run("if [[ -d #{deploy_to}/shared/posts ]]; then ln -nfs #{deploy_to}/shared/posts #{deploy_to}/current/; fi")
	end
	desc "Save the post folder"
	task :save_posts do
		run("if [[ -d #{deploy_to}/current/posts && ! -d #{deploy_to}/shared/posts ]]; then mv #{deploy_to}/current/posts #{deploy_to}/shared/; fi")
	end
	desc "Keep the config file"
	task :config do
	  run("if [[ ! -f #{deploy_to}/shared/config.yml ]]; then cp #{deploy_to}/current/config/config.yml #{deploy_to}/shared/; fi")
	  run("ln -nfs #{deploy_to}/shared/config.yml #{deploy_to}/current/config/")
	end
	# link shared tasks with deploy:update_code
  after "deploy:symlink" do
	  "init:setup" # give write right on new folder
	  link_posts
		config
	end
	before "deploy:symlink", "init:setup", "shared:save_posts" # give write right on new folder
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
	  run("rvm gemset create #{application}")
		run("rvm list gemsets")
	end
	desc "Create .rvmrc file for this application"
	  task :rvmrc, :role => :app do
		run("echo 'rvm use #{ruby}@#{application} > /dev/null' > #{deploy_to}/.rvmrc")
    run("rvm rvmrc trust #{deploy_to}/.rvmrc")
  end
	# Thin configuration
	desc "Create a thin config and service files"
	task :thin, :role => :app do
	  sudo("mkdir -p /etc/thin/#{application}")
		sudo("mkdir -p /var/log/thin/")
	  sudo("thin -c #{deploy_to}/current -S /tmp/#{application}.sock -l /var/log/thin/#{application}.log -s 1 -C /etc/thin/#{application}/#{application}.yml -e production config")
		sudo("thin install")
		sudo("mv /etc/init.d/thin /etc/init.d/#{application}")
		sudo("rvm wrapper #{ruby}@#{application} #{application} thin") # create /usr/local/bin/app_thin
		sudo("sed -i 's#DAEMON=.*#DAEMON=/usr/local/bin/#{application}_thin#g' /etc/init.d/#{application}")
		sudo("sed -i 's#SCRIPT_NAME=.*#SCRIPT_NAME=/etc/init.d/#{application}#g' /etc/init.d/#{application}")
		sudo("sed -i 's#CONFIG_PATH=.*#CONFIG_PATH=/etc/thin/#{application}#g' /etc/init.d/#{application}")
		sudo("/usr/sbin/update-rc.d #{application} defaults")
	end
	# link init tasks with deploy:setup
	before "deploy:setup" do
	  rvm
	end
  after "deploy:setup" do
    setup
    nginx
		rvmrc
    thin
  end
end

