require 'sinatra'
require 'models/post'
require 'haml'

module Blog
  class Application < Sinatra::Application

    # root
    get '/' do
      @posts = Post.all('posts')
      haml :index
    end

  end
end
