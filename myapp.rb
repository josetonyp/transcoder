# myapp.rb
require 'sinatra'
require 'pry'
require 'zip'
require 'fileutils'

get '/' do
  page = params["page"].nil? ? 1 : params["page"].to_i
  per_page=30
  from = (page - 1) * per_page
  to = from + (per_page-1)
  files = Dir.glob( "public/audio/*.wav" )
  ready_files = Dir.glob( "public/output/*" )
  erb :home, :layout=>:myapp, locals: { files: files[from..to], total: files.count, page:page, pages: (files.count / per_page).ceil, ready_files:ready_files.count }
end

post  "/update" do
  File.open(params["id"], "w"){|file| file.puts(params["value"].strip) }
end

post  "/save" do
  params["files"].each do |file|
    begin
      FileUtils.copy file, file.gsub("audio/", "output/")
    rescue
      # :P
    end
  end
end

get "/files" do
  zipfile_name = "public/files.zip"
  File.delete( zipfile_name ) if File.exist?( zipfile_name)

  Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
    Dir.glob( "public/output/*" ).each do |filename|
      # Two arguments:
      # - The name of the file as it will appear in the archive
      # - The original file, including the path to find it
      zipfile.add(filename.gsub("public/output/",""),filename)
    end
  end
  Dir.glob( "public/output/*" ).each do |filename|
    File.delete( filename )
  end

  send_file zipfile_name
end




