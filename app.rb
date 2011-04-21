require 'sinatra'
require 'haml'
require 'models/post'
require 'models/repo'
require 'digest/md5'

module Blog
  class Application < Sinatra::Application

    configure do
      # Defaults values
      set :configs     => 'config'
      set :name        => 'Yublog'
      set :description => 'Git blog engine'
      set :repo        => {
        'name' => '.',      # repo path
        'path' => '/posts'  # relative path to posts, root is the repo
      }

      # Read config file
      if File.exist?(settings.configs + "/config.yml")
        cfg = YAML.load_file( settings.configs + "/config.yml")
        if cfg then
          cfg.each_pair do |key, value|
            set(key.to_sym, value) if value != nil
          end
        end
      end
      settings.repo['path'] = '' if settings.repo['path']==nil
      settings.repo['url'] = '' if settings.repo['url']==nil

      # Clone the repository if needed
      if settings.repo['url'] != "" and !Dir.exist?(settings.repo['name']) then
        puts settings.repo['url']
        Blog::Repo.clone(settings.repo['url'], settings.repo['name'])
      end
    end

    # web hook collector
    # github ready (http://help.github.com/post-receive-hooks/)
    post '/hook/:key' do
      if params[:key] == settings.repo['key'].to_s then
        Blog::Repo.pull(settings.repo['name'])
      end
    end

    # root, posts index
    get '/' do
      @title = 'Welcome'
      @posts = Post.all(settings.repo['name'], settings.repo['path'])
      haml :index
    end

    # view a blog post
    get '/:year/:month/:day/:title' do
      # post filename
      filename = "#{params[:year]}-#{params[:month]}-#{params[:day]}-#{params[:title]}.md"
      # git repo
      repo = Blog::Repo.new(settings.repo['name']) if Blog::Repo.is_git?(settings.repo['name'])
      # build a hash with infos extracted from git
      infos = Hash.new
      if Blog::Repo.is_git?(settings.repo['name']) then
        git_infos = repo.published_infos(filename)
        infos[:author_name] = git_infos[:name]
        infos[:author_email] = git_infos[:email]
        infos[:published] = git_infos[:date]
        #  test if the file has been modifed
        if repo.history(filename).count > 1 then
          git_infos = repo.last_change(filename)
          infos[:last_modified] = git_infos[:date]
          infos[:last_author_name] = git_infos[:name]
          infos[:last_author_email] = git_infos[:email]
        end
      end
      @post = Post.new(
        settings.repo['name']+settings.repo['path']+ '/' + filename,
        infos
      )
      # Print a gravatar if we have an email
      if @post.last_modified && @post.last_author_email then
        @avatar = "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(@post.last_author_email)}"
      elsif !@post.last_modified && @post.author_email
        @avatar = "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(@post.author_email)}"
      end
      @title = @post.title
      haml :show
    end
  end
end
