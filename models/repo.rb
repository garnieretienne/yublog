require 'grit'

module Blog
  class Repo
    # Declare a new local git repository
    #   path = '../posts'
    #   repo = Blog::Repo.new(path)
    def initialize(path)
      @repo = Grit::Repo.new(path)
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
        history << "modified by #{author.name} on #{date}"
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
      change[:date] = commits.last.date
      author = Grit::Actor.from_string(commits.last.author_string)
      change[:name] = author.name
      change[:email] = author.email
      return change
    end
  end
end
