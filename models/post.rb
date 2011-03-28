require 'maruku'
require 'yaml'

module Blog
  class Post

    attr_reader :title, :timestamp

    # Create a post object with a source file
    # (YAML header + markdown)
    #   source = "posts/03-27-2011-new_blog_open.md"
    #   post = Blog::Post.new(source)
    #   title = post.title
    #   date = Time.at(post.timestamp)
    def initialize(source)
      # read the source
      raw = File.read(source)
      # parse the source and get the metadata and content
      parse_source(raw)
      @title = @data['title']
      @timestamp = @data['timestamp'].to_i
    end

    # return the post source converted into html
    #   source = "posts/03-27-2011-new_blog_open.md"
    #   post = Blog::Post.new(source)
    #   html = post.to_html
    def to_html
      @content.to_html
    end

    # Alias method, to_s = to_html
    #   source = "posts/03-27-2011-new_blog_open.md"
    #   post = Blog::Post.new(source)
    #   puts post => HTML
    alias_method :to_s, :to_html    

    # Return an Array of all the post in the 'base' repository
    #   posts = Blog::Post.all('./posts')
    def self.all(base='.')
      posts_sources = Dir.glob(base + '/*')
      posts = Array.new
      posts_sources.each do |source|
        posts << Blog::Post.new(source)
      end
      return posts
    end

    private

    # Parse a YAML+Markdown source code and 
    # provide metadata and post content
    def parse_source(raw)
      if raw =~ /^(---\s*\n.*?\n?)^(---.*)/m
        begin
          @data = YAML.load($1)
          @content = Maruku.new($2)
        rescue Exception => e
          puts "Parse Exception: #{e.message}"
        end
      end
    end

  end
end

