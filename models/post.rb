require 'rdiscount'
require 'yaml'
require 'albino'
require 'models/repo'

module Blog
  class Post

    #attr_reader :id, :title, :timestamp, :year, :month, :day
    attr_reader :id                 # formated post title
    attr_reader :title              # post title
    attr_reader :published          # post publication date
    attr_reader :year, :month, :day # published date informations, filename extracted
    attr_reader :author_name        # post author name
    attr_reader :author_email       # post author email
    attr_reader :last_modified      # date of last modification
    attr_reader :last_author_name   # last modification author name
    attr_reader :last_author_email  # last modification author email

    # Create a post object with a source file
    # (YAML header + markdown)
    #   source = "posts/2011-01-01-new_blog_open.md"
    #   post = Blog::Post.new(source)
    #   title = post.title
    #   date = Time.at(post.timestamp)
    # Info hash can content any of the following attr:
    #   * :published
    #   * :author_name
    #   * :author_email
    #   * :last_modified
    #   * :last_author_name
    #   * :last_author_email
    def initialize(source, info_hash=Hash.new)
      @infos = info_hash
      raise "The Post source file does not exist (#{source})" if !File.exist?(source)
      # read the source
      raw = File.read(source)
      # parse the source and get the metadata and content
      parse_source(raw)
      raise "The Post source file does not contain any metadata (YAML header)" if @data == nil
      parse_filename(source)
      set_attributes
    end

    # return the post source converted into html
    #   source = "posts/03-27-2011-new_blog_open.md"
    #   post = Blog::Post.new(source)
    #   html = post.to_html
    def to_html
      highlight_codes
      RDiscount.new(@content, :autolink).to_html
    end

    # Alias method, to_s = to_html
    #   source = "posts/03-27-2011-new_blog_open.md"
    #   post = Blog::Post.new(source)
    #   puts post => HTML
    alias_method :to_s, :to_html    

    # Return an Array of all posts in the 'base' repository
    #   posts = Blog::Post.all('./posts')
    def self.all(base='.', path="/")
      repo = Blog::Repo.new(base)
      posts_sources = Dir.glob(base + path + '/*.md').sort{|x,y| y <=> x}
      posts = Array.new
      posts_sources.each do |source|
        infos = Hash.new
        filename = source.split('/').last
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
        posts << Blog::Post.new(source, infos) if Blog::Post.smells_good?(source)
      end
      return posts
    end

    # Test if the given source is a good formated post source
    def self.smells_good?(file)
      raw = File.read(file)
      if raw =~ /^.*title:\s.*?\n\n.*/m then
        return true
      else
        return false
      end
    end

    private

    # Parse a YAML+Markdown source code and 
    # provide metadata and post content
    def parse_source(raw)
      if raw =~ /^(.*title:\s.*?)\n\n(.*)/m then
        begin
          @data = YAML.load($1)
          @content = $2
        rescue Exception => e
          raise "Parse Exception: #{e.message}"
        end
      end
    end

    # Parse the filename to get the post published 
    # date and the url id
    def parse_filename(source)
      if source =~ /^.*(\d{4})-(\d{2})-(\d{2})-(.*)\.md$/ then
        @year = $1
        @month = $2
        @day = $3
        @id = $4
      end
    end

    # Highlight the codes with pygment
    def highlight_codes
      @content.gsub!(/%(.*?){(.*?)}%/m) do
        lang = :text
        lang = $1 if $1 != ""
        Albino.colorize($2, lang)
      end
    end

    # Set attribute with YAML header or info_hash
    def set_attributes
      # (needed) set title
      if @data['title'] then
        @title = @data['title']
      else
        raise "This post (#{@id}) miss a title"
      end
      # (needed) set author
      if @data['author'] then
        @author_name = @data['author']
      elsif @infos[:author_name]
        @author_name = @infos[:author_name]
      else
        @author_name = 'unknown'
      end
      if @data['email'] then
        @author_email = @data['email']
      else
        @author_email = @infos[:author_email]
      end
      # (needed) set published, if found nowhere, use filename date
      if @data['published'] then
        @published = Time.at(@data['published'])
      elsif @infos[:published]
        @published = @infos[:published]
      else
        @published = Time.mktime(@year, @month, @day)
      end
      # (optional) set last modification date
      @last_modified = @infos[:last_modified] if @infos[:last_modified]
      # (optional) set last modification author name
      @last_author_name = @infos[:last_author_name] if @infos[:last_author_name]
      # (optional) set last modification author email
      @last_author_email = @infos[:last_author_email] if @infos[:last_author_email]
    end
  end
end

