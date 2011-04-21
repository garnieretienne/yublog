#require File.expand_path(File.dirname(__FILE__) + "/app")
$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

Encoding.default_external = "utf-8"

require 'app'

run Blog::Application
