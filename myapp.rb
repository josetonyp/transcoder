# myapp.rb
require 'sinatra'
require 'pry'
require 'zip'
require 'fileutils'
require 'mongoid'
require 'will_paginate_mongoid'
require 'bcrypt'
require 'waveinfo'
require_relative 'models/user'
require_relative 'models/audio'



configure :development do

  enable :sessions, :logging, :dump_errors, :inline_templates
  set :session_secret, "asdfasfd asfda sfd asfd asfda"
  logger = Logger.new($stdout)

  Mongoid.load!("config/mongoid.yml")

end

get '/import' do
  AudioFile.delete_all
  Dir.glob( "public/audio/*.wav" ).map{|file| file.gsub("public/audio/", "") }.each do |file|
    AudioFile.create!( name: file ) unless AudioFile.where(name: file).exists?
  end
end

get '/' do
  session['m'] = 'Hello World!' # Register user here
  page = params["page"].nil? ? 1 : params["page"].to_i
  audios = AudioFile.paginate( page: page, per_page: 30 )
  erb :empty, :layout=>:myapp
end

post  "/update" do
  AudioFile.where(name: params["id"]).first.update_attributes!( translation: params["value"].strip)
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

before do
  @user = session.key?("user") ?  User.find(session["user"]) : nil
end

# AudioFiles

get '/audio_files' do
  content_type :json
  if @user
    page = params["page"].nil? ? 1 : params["page"].to_i
    AudioFile.paginate( page: page, per_page: 30 ).map(&:prep_json).to_json
  end
end

get '/audio_files/review' do
  content_type :json
  if @user
    page = params["page"].nil? ? 1 : params["page"].to_i
    AudioFile.where(status:"translated").paginate( page: page, per_page: 30 ).map(&:prep_json).to_json
  end
end

get '/audio_files/:file' do
  content_type :json
  if @user
    AudioFile.find(params["file"]).to_json
  end
end

put '/audio_files/:file' do
  content_type :json
  if @user
    audio = AudioFile.find(params["file"])
    audio.update_attributes!( translation: params["value"].strip, status: "translated", translator: @user ) if params["value"] != "" && params["value"] != "[bad wave] ??"
    audio.to_json
  end
end

put '/audio_files/:file/reviewed' do
  content_type :json
  if @user
    audio = AudioFile.find(params["file"])
    audio.update_attributes!( status: "reviewed", reviewer: @user )
    audio.to_json
  end
end


# AudioFolders

get '/audio_folders/import' do
  content_type :json
  if @user && @user.admin
    AudioFile.destroy_all
    AudioFolder.destroy_all
    AudioFolder.import
    AudioFolder.all.map(&:status).to_json
  end
end

get '/audio_folders' do
  content_type :json
  if @user
    page = params["page"].nil? ? 1 : params["page"].to_i
    AudioFile.paginate( page: page, per_page: 30 ).map(&:prep_json).to_json
    AudioFolder.all.map(&:status).to_json
  end
end

get '/audio_folders/:id' do
  content_type :json
  if @user
    page = params["page"].nil? ? 1 : params["page"].to_i
    AudioFolder.find(params[:id]).prep_json( page ).to_json
  end
end


# User

get '/users' do
  if @user and @user.admin
    User.all.map(&:prep_json).to_json
  end
end

get '/account' do
  @user.to_json
end

post '/account/login' do
  content_type :json
  params =  JSON.parse(request.body.read)
  user = User.where( email:params["email"]).first
  if user && user.password == params["password"]
    user.token = SecureRandom.urlsafe_base64(nil, false)
    session["user"] = user.id
    user.to_json
  else
    session.destroy
    {}.to_json
  end
end

post '/account/logout' do
  session.destroy
end


