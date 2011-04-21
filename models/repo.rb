require 'grit'

module Blog
  class Repo
    # Declare a new local git repository
    #   path = '../posts'
    #   repo = Blog::Repo.new(path)
    def initialize(base='.', path='/')
      @repo = Grit::Repo.new(base)
    end

    # Get the change history on a file
    #   post = '2011-03-27-new_blog_open.md'
    #   history = repo.history(post)
    #   puts history.last
    def history(filename)
      commits = @repo.log('master', filename)
      history = Array.new
      commits.each do |commit|
        date = commit.date
        author = Grit::Actor.from_string(commit.author_string)
        if commit.sha == commits.last.sha then
          history << "created by #{author.name} on #{date}"
        else
          history << "modified by #{author.name} on #{date}"
        end
      end
      return history
    end

    # Get the informations about last change on the file
    #   post = '2011-03-27-new_blog_open.md'
    #   infos = repo.last_change(post)
    #   email_hash = Digest::MD5.hexdigest(infos[:email])
    #   gravatar = "http://www.gravatar.com/avatar/#{email_hash}"
    def last_change(filename)
      change = {
        :date  => nil,
        :name  => nil,
        :email => nil,
      }
      commits = @repo.log('master', filename)
      if !commits.empty? then
        change[:date] = commits.first.date
        author = Grit::Actor.from_string(commits.first.author_string)
        change[:name] = author.name
        change[:email] = author.email
      end
      return change
    end

    # Get the informations about the first publication of the file
    #   post = '2011-03-27-new_blog_open.md'
    #   infos = repo.published_infos(post)
    #   author = Digest::MD5.hexdigest(infos[:name])
    def published_infos(filename)
      change = {
        :date  => nil,
        :name  => nil,
        :email => nil,
      }
      commits = @repo.log('master', filename)
      if !commits.empty? then
        change[:date] = commits.last.date
        author = Grit::Actor.from_string(commits.last.author_string)
        change[:name] = author.name
        change[:email] = author.email
      end
      return change
    end

    # Clone the given repository in a path,
    # Require git system command
    #   url = "http://github.com/garnieretienne/blog-content.git"
    #   path = "posts"
    #   Blog::Repo.clone(url, path)
    #   repo = Blog::Repo.new(path)
    def self.clone(url, path)
      raise "Git: the path (#{path} selected as the destination already exist)" if Dir.exist?(path)
      result = system "git clone #{url} #{path} > /dev/null 2> /dev/null"
      raise "'git clone #{url} #{path}' failed (is git installed ?)" if !result
    end

    # Pull the given repository (origin/master)
    # Require git repo and git system command
    #   Blog::Repo.clone(url, path)
    #   Blog::Repo.pull(path)
    def self.pull(path)
      raise "Git: the path (#{path}) doesn't exist" if !Dir.exist?(path)
      result = system "cd #{path} && git pull origin master > /dev/null 2> /dev/null"
      raise "git clone failed (is git installed ?)" if !result
    end

    # Test if a folder is a git repository
    #   Blog::Repo.is_git?(folder)
    def self.is_git?(folder)
      return true if Dir.exist?("#{folder}/.git/")
      return false
    end
  end
end
