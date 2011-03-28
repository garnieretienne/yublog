require 'sinatra'
require 'models/post'
require 'haml'

module Blog
  class Application < Sinatra::Application

    # root, posts index
    get '/' do
      @posts = Post.all('posts')
      haml :index
    end

    # view a blog post
    get '/:year/:month/:day/:title' do
      @post = Post.new('posts/' + "#{params[:year]}-#{params[:month]}-#{params[:day]}-#{params[:title]}.md")
      haml :view
    end
  end
end
