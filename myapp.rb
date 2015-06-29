# Start pry console
# ./console

# myapp.rb
require 'sinatra'
require 'pry'
require 'zip'
require 'fileutils'
require 'mongoid'
require 'will_paginate_mongoid'
require 'bcrypt'
require 'waveinfo'
require 'awesome_print'
require_relative 'models/user'
require_relative 'models/audio'

APPROOT = File.expand_path(File.dirname(__FILE__))

configure :development do
  enable :sessions, :logging, :dump_errors, :inline_templates
  set :session_secret, "asdfasfd asfda sfd asfd asfda"
  logger = Logger.new($stdout)

  Mongoid.load!("config/mongoid.yml")
end

get '/' do
  session['m'] = 'Hello World!' # Register user here
  page = params["page"].nil? ? 1 : params["page"].to_i
  audios = AudioFile.paginate( page: page, per_page: 30 )
  erb :empty, :layout=>:myapp
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
    if params['review'] == "true"
      audio.update_attributes!( status: "reviewed", reviewer: @user )
    else
      audio.update_attributes!( translation: params["value"].strip, status: "translated", translator: @user ) if params["value"] != "" && params["value"] != "[bad wave] ??"
    end
    audio.reload.to_json
  end
end


# AudioFolders

# get '/audio_folders/import' do
#   content_type :json
#   if @user && @user.admin
#     AudioFile.destroy_all
#     AudioFolder.destroy_all
#     AudioFolder.import
#     AudioFolder.all.map(&:status).to_json
#   end
# end

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
    AudioFolder.find(params[:id]).prep_json( page, review: false ).to_json
  end
end

get '/audio_folders_dowload/:id' do
  return unless @user
  folder = AudioFolder.find(params[:id])
  folder.build
  send_file folder.zipfile_name, filename: folder.zipfile_name
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


