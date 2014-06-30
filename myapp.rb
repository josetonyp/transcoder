# myapp.rb
require 'sinatra'
require 'pry'


# class MyApp < Sinatra::Application
#
#   class << self
#
#     get '/' do
#       'Hello world!'
#     end
#
#   end
#
# end
#
# MyApp.run if __FILE__ == $0



get '/' do
  page = params["page"].to_i || 1
  per_page=20
  from = (page - 1) * per_page
  to = from + (per_page-1)
  files = Dir.glob( "public/audio/*.wav" )
  erb :home, :layout=>:myapp, locals: { files: files[from..to], total: files.count, page:page, pages: (files.count / per_page).ceil }
end

post  "/update" do
  File.open(params["id"], "w"){|file| file.puts(params["value"].strip) }
end




