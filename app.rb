require 'sinatra'
require 'models/post'
require 'haml'

module Blog
  class Application < Sinatra::Application

    configure do
      # Defaults values
      set :configs     => 'config'
      set :base        => 'posts'
      set :name        => 'Blog'
      set :description => 'Blog engine'

      # Read config file
      if File.exist?(settings.configs + "/config.yml")
        cfg = YAML.load_file( settings.configs + "/config.yml")
        cfg.each_pair do |key, value|
          set(key.to_sym, value) if value != nil
        end
      end
    end

    # root, posts index
    get '/' do
      @title = 'Welcome'
      @posts = Post.all(settings.base)
      haml :index
    end

    # view a blog post
    get '/:year/:month/:day/:title' do
      @post = Post.new(settings.base + '/' + "#{params[:year]}-#{params[:month]}-#{params[:day]}-#{params[:title]}.md")
      @title = @post.title
      haml :view
    end
  end
end
