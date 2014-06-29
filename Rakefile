# require "bundler/gem_tasks"

gem "activerecord"
require 'active_record'

database_rake_path = "%s/gems/activerecord-%s/lib/active_record/railties/databases.rake" \
                     % [ ENV['GEM_HOME'],  ActiveRecord::VERSION::STRING ]


# /Users/ej/.rvm/gems/ruby-1.8.7-p352/gems/railties-3.0.10/lib/rails/tasks/misc.rake

misc_rake_path = "%s/gems/railties-%s/lib/rails/tasks/misc.rake" \
                  % [ ENV['GEM_HOME'],  ActiveRecord::VERSION::STRING ]


import misc_rake_path
import database_rake_path

task :environment do

  ENV['RACK_ENV'] ||= 'development'
  dbconf = YAML.load_file('config/database.yml')
  ActiveRecord::Base.establish_connection( dbconf[ ENV['RACK_ENV'] ] )
  ActiveRecord::Base.pluralize_table_names = false

end
