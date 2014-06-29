$:.unshift(File.expand_path(File.dirname(__FILE__)))

require 'myapp'

# run MyApp
run Sinatra::Application