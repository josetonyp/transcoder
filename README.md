# sinatra sandbox

## sinatra

- handles URLs
  - get / post / put, etc.
  - parse params form url, e.g.

        get '/.?:format?' do; params[:format]; end;

- ruby
- files:
  - myapp.rb
  - config.ru

## unicorn
- *Designed for Rack, Unix, fast clients, and ease-of-debugging. We cut out everything that is better supported by the operating system, nginx or Rack.*
- [README](http://unicorn.bogomips.org/README.html)


## activerecord

- object-relational mapping to database
- files:
  - config/database.yml
    - provides: *database config*
  - db/development.sqlite3
     - provides: *database*
  - models.rb
    - provides: *ActiveRecord model definitions*
  - Rakefile
    - provides: *ActiveRecord Rake tasks: db:migrate, etc.*

## erb

- files:
  - views/myapp.erb
    - provides: *layout*
  - views/_partial.erb
    - provides: *partial*
  - views/index.erb
    - provides: *index page*
- html
- ruby
