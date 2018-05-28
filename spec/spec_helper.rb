require 'rspec'
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

Mongoid.load!("./config/mongoid.yml", 'test')


Dir.glob("models/concerns/**/*.rb") { |file| require File.expand_path(file) }
Dir.glob("models/*.rb") { |file| require File.expand_path(file) }
Dir.glob("spec/support/*.rb") { |file| require File.expand_path(file) }

RSpec.configure do |config|
  config.before(:each) do
    AudioFolder.destroy_all
    AudioFile.destroy_all
  end
end
