require "bundler/capistrano"

# Yuweb config
# ------------

# Variables
app_name   = 'kurtblog'
app_server = 'leia.blcdn.net'
user       = 'kurt'
git_url    = 'git@github.com:garnieretienne/yublog.git'
git_branch = 'kurt.yuweb.fr'

# Bundler
set :bundle_without,  [:development, :test]
set :bundle_flags,    "--deployment --quiet --binstubs"

# Rbenv
set :default_environment, {
  'PATH' => "/usr/local/rbenv/shims:/usr/local/rbenv/bin:$PATH"
}
after "bundle:install", :roles => [:web, :db, :app] do
  run "rbenv rehash"
end

# General
set :application, app_name
set :deploy_to, "/var/app/#{app_name}"
set :user, user
set :use_sudo, false
ssh_options[:forward_agent] = true
default_run_options[:pty] = true

# Role
role :web, app_server
role :app, app_server
role :db,  app_server, :primary => true

# Git
set :repository,  git_url
set :branch,      git_branch
set :scm, :git
set :deploy_via, :remote_cache

# Thin management
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
end

# Fix permissions
after "deploy:update_code", :roles => [:web, :db, :app] do
  sudo "chown -R #{application}:sysadmin #{deploy_to}/*"
  sudo "chmod -R 775 #{deploy_to}/*"
end

# Custom rules
# ------------

# No database migration
namespace:deploy do
  task :cold do
    deploy.update
  end
  task :migrate do
  end
  task :migrations do
  end
end

# Shared folders
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
    link_posts
    config
  end
  before "deploy:symlink", "shared:save_posts" # give write right on new folder
end
