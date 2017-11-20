# Start pry console
# ./console

# myapp.rb
require 'sinatra'
require 'sinatra/namespace'
require 'pry'
require 'zip'
require 'fileutils'
require 'mongoid'
require 'will_paginate_mongoid'
require 'bcrypt'
require 'waveinfo'
require 'awesome_print'
require 'pry'
require 'pry-doc'

Dir.glob("models/concerns/*.rb").each {|file| require_relative file }
Dir.glob("models/*.rb").each {|file| require_relative file }


APPROOT = File.expand_path(File.dirname(__FILE__))

class AllButFiles
  Match = Struct.new(:captures)

  def initialize()
    @captures = Match.new([])
  end

  def match(str)
    @captures unless str.match(/^\/(views|javascripts|css|audio|output|api)/)
  end
end

configure :development do
  enable :sessions, :logging, :dump_errors, :inline_templates
  set :session_secret, "asdfasfd asfda sfd asfd asfda"
  logger = Logger.new($stdout)

  Mongoid.load!("./config/mongoid.yml")
end

get AllButFiles.new do
  session['m'] = 'Hello World!' # Register user here
  page = params["page"].nil? ? 1 : params["page"].to_i
  audios = AudioFile.paginate( page: page, per_page: 30 )
  erb :empty
end

before do
  @user = session.key?("user") ?  User.find(session["user"]) : nil
end

namespace '/api' do

  # Audios

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
      audio = AudioFile.find(params['file'])
      audio.translate( translation: params['value'], user: @user, review: params['review'] == "true")
      audio.reload.to_json
    end
  end

  # Folders

  get '/audio_folders' do
    content_type :json
    if @user
      if params[:count].to_s == 1.to_s
        [AudioFolder.count].to_json
      else
        page = params["page"].nil? ? 1 : params["page"].to_i
        folders = if params[:filter].nil? || params[:filter].empty?
          AudioFolder
        else
          AudioFolder.where(status: params[:filter])
        end

        unless @user.admin?
          folders = folders.for_user(@user)
        end

        folders = folders.paginate(page:page, per_page: 10)

        {folders: folders.map(&:as_audio_attributes),
          total: folders.total_entries,
          pages: folders.total_pages}.to_json
      end
    end
  end

  get '/audio_folders/:id' do
    content_type :json
    if @user
      page = params["page"].nil? ? 1 : params["page"].to_i
      AudioFolder.find(params[:id]).prep_json( page, review: false ).to_json
    end
  end

  get '/audio_folders/:id/process_files' do
    content_type :json
    if @user and @user.admin
      folder = AudioFolder.find(params[:id])
      folder.digest_audio_files
      folder.update_folder_duration
      folder.destroy_wav_files_folder
    end
  end

  get '/audio_folders/:id/reviewed' do
    content_type :json
    if @user and @user.admin
      folder = AudioFolder.find(params[:id])
      folder.audio_files.just_translated.all.each do |audio|
        audio.reviewed_by!(user: @user)
      end

      page = params["page"].nil? ? 1 : params["page"].to_i
      folder.prep_json( page, review: false ).to_json
    end
  end

  put '/audio_folders/:id' do
    content_type :json
    folder = AudioFolder.find(params[:id])
    @user= User.find(params[:user_id])
    if @user
      folder.take_by(@user) unless folder.audio_files.active_translated.any?
      AudioFolder.all.map(&:as_audio_attributes).to_json
    end
  end

  get '/audio_folders_dowload/:id' do
    return unless @user
    folder = AudioFolder.find(params[:id])
    if folder.reviewed? || folder.downloaded?
      folder.build
      folder.next!
      send_file(folder.zipfile_name, filename: folder.zipfile_name)
    end
  end

  post '/upload_folder' do
    if @user and @user.admin
      tempfile = params[:file][:tempfile]
      filename = File.join(APPROOT,"folders", params[:file][:filename])
      FileUtils.copy(tempfile.path, filename)
      AudioFolder.digest(filename)
    end
    redirect "/home"
  end

  # User

  get '/users' do
    if @user and @user.admin
      if params.include?("short") && params["short"].to_s == 1.to_s
        User.all.map(&:min_json)
      else
        User.all.map(&:prep_json)
      end.to_json
    end
  end

  get '/account' do
    if @user
      @user.to_json
    else
      status 404
      {}.to_json
    end
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
      status 404
      session.destroy
      { error: "User not found, please check username and password"}.to_json
    end
  end

  post '/account/logout' do
    session.destroy
  end

end

