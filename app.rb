require "sinatra"
require 'active_record'
require "sinatra/reloader"

set :environment, :production

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development


