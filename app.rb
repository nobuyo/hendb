require "sinatra"
require "sinatra/reloader"
require "sinatra/namespace"
require 'active_record'
require 'rack/flash'

require_relative 'models/user'
require_relative 'models/univ'
require_relative 'models/aspireUniv'
require_relative 'models/exam'
require_relative 'models/subject'

set :environment, :production

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

configure do
  use Rack::Flash
end

enable :sessions
  set :session_secret, "My session secret", expire_after: 3

namespace '/auth' do
  get '/sign_up' do
    session[:user_id] ||= nil
    if session[:user_id]
      redirect '/'
    end
    # if flash[:notice]
      flash[:notice]
    # end

    slim :sign_up
  end

  get '/sign_in' do
    session[:user_id] ||= nil
    if session[:user_id]
      redirect '/'
    end

    slim :sign_in
  end

  post '/register' do
    unless User.exists?(email: params[:email])
      if params[:password] == params[:confirm_password]
        user = User.new(email: params[:email])
        user.encrypt_password(params[:password])
        if user.save!
          flash[:notice] = "register succeeded"
          session[:user_id] = user.id
          redirect "/"
        end
      end
    else
      user = User.auth(params[:email], params[:password])
      if user
          session[:user_id] = user.id
          redirect '/'
      else
        redirect "/auth/sign_in"
      end
    end
  end
end

get '/' do
  slim :index
end
