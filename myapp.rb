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

Dir.glob("models/concerns/**/*.rb").each {|file| require_relative file }
Dir.glob("models/*.rb").each {|file| require_relative file }
Dir.glob("models/importers/*.rb").each {|file| require_relative file }


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
      if params['review'] == "true"
        audio.reviewed_by(user: @user)
      else
        audio.translated_by(translation: params['value'], user: @user)
      end
      audio.reload.to_json
    end
  end

  # Folders

  get '/audio_folders' do
    content_type :json
    if @user
      if params[:count].to_s == 1.to_s
        [AudioFolder.by_index.count].to_json
      else
        page = params["page"].nil? ? 1 : params["page"].to_i
        folders = if params[:filter].nil? || params[:filter].empty?
          AudioFolder.by_index
        else
          AudioFolder.by_index.where(status: params[:filter])
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
      AudioFolder.by_index.find(params[:id]).prep_json( page, review: false ).to_json
    end
  end

  get '/audio_folders/:id/process_files' do
    content_type :json
    if @user and @user.admin
      folder = AudioFolder.by_index.find(params[:id])
      folder.digest_audio_files
      folder.update_folder_duration
      folder.destroy_wav_files_folder
    end
  end

  get '/audio_folders/:id/reviewed' do
    content_type :json
    if @user and @user.admin
      folder = AudioFolder.by_index.find(params[:id])
      folder.audio_files.translated.all.each do |audio|
        audio.reviewed_by(user: @user)
      end
      folder.next!
      page = params["page"].nil? ? 1 : params["page"].to_i
      folder.prep_json( page, review: false ).to_json
    end
  end

  put '/audio_folders/:id' do
    content_type :json
    if @user and @user.admin
      folder = AudioFolder.by_index.find(params[:id])
      taking_user= User.find(params[:user_id])
      if taking_user
        folder.take_by(taking_user) unless folder.audio_files.translated.any?
        true
      end
    end
  end

  get '/audio_folders_dowload/:id' do
    return unless @user and @user.admin
    folder = AudioFolder.by_index.find(params[:id])
    if folder.reviewed? || folder.downloaded?
      folder.build
      folder.downloaded!
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
      users = AudioFolder.includes(:translator).distinct(:translator).compact.map{|id| User.find(id)}
      if params.include?("short") && params["short"].to_s == 1.to_s
        users.map(&:min_json)
      else
        users.map(&:to_h)
      end.to_json
    end
  end

  get '/users/:id' do
    if @user and @user.admin
      User.find(params[:id]).to_h.to_json
    end
  end

  get '/users/:id/folders' do
    if @user and @user.admin
      @tuser = User.find(params[:id])
      @audio_folders = @tuser.audio_folders
      @audio_folders.map(&:as_audio_attributes).to_json
    end
  end

  get '/users/:id/invoices' do
    if @user and @user.admin
      user = User.find(params[:id])
      AudioFolder.for_user(user).map(&:invoice).uniq.map{|i| i.to_h(user)}.to_json
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

