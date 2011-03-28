require 'sinatra'
require 'models/post'

module Blog
  class Application < Sinatra::Application

    # root
    get '/' do
      "Hello World"
    end

  end
end
