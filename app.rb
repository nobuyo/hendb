require "sinatra"
require "sinatra/reloader"
require "sinatra/namespace"
require 'active_record'

require_relative 'models/user'
require_relative 'models/univ'
require_relative 'models/aspireUniv'
require_relative 'models/exam'

set :environment, :production

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

enable :sessions
set :session_secret, "My session secret", expire_after: 300

helpers do
  def link_to(url, txt=url)
    %Q(<a href="#{url}">#{txt}</a>)
  end

  def translate_to_subject(nb)
    %w(国語 数学 物理 化学 英語 TOEIC/TOEFL 専門 面接 小論文)[nb-1]
  end
end

namespace '/auth' do
  get '/sign_up' do
    session[:user_id] ||= nil
    if session[:user_id]
      redirect '/'
    end

    slim :'auth/sign_up'
  end

  get '/sign_in' do
    session[:user_id] ||= nil
    if session[:user_id]
      redirect '/'
    end

    slim :'auth/sign_in'
  end

  get '/sign_out' do
    session[:user_id] = nil
    redirect '/auth/sign_in'
  end

  post '/register' do
    unless User.exists?(email: params[:email])
      if params[:password] == params[:confirm_password]
        user = User.new(email: params[:email])
        user.encrypt_password(params[:password])
        if user.save!
          session[:user_id] = user.id
          redirect "/"
        end
      end
    else
      redirect "/auth/sign_in"
    end
  end

  post '/authenticate' do
    user = User.auth(params[:email], params[:password])
    unless user.nil?
      session[:user_id] = user.id
      redirect '/'
    else
      redirect "/auth/sign_in"
    end
  end
end

before do
  if session[:user_id]
    @user = User.find(session[:user_id])
  end
end

before '/data/*' do
  unless session[:user_id]
    redirect "/auth/sign_in"
  end
end

namespace '/data' do
  get '/' do
    @data = Univ.all
    slim :'data/index'
  end

  get '/new' do
    slim :'data/new'
  end

  get '/bookmarks' do
    @bookmark = true
    @data = @user.aspireUnivs

    slim :'data/bookmarks'
  end

  post '/bookmark' do
    user = @user
    unless user.aspireUnivs.exists?(univ_id: params[:univ_id])
      user.aspireUnivs.create!(univ_id: params[:univ_id])
      redirect '/data/'
    else
      au = user.aspireUnivs.find_by(univ_id: params[:univ_id])
      au.destroy!
      redirect '/data/'
    end
  end

  get '/search' do
    @data = Univ.where('name like ? or pref like ? or dept like ?', "%#{params[:q]}%")
    slim :'data/index'
  end

  post '/create' do
    unless Univ.exists?(name: params[:name])
      univ = Univ.new(name: params[:name], dept: params[:dept],
        pref: params[:pref], deviation_value: params[:deviation_value],
        exam_date: params[:exam_date], result_date: params[:result_date],
        affirmation_date: params[:affirmation_date], url: params[:url], remark: params[:remark])
      params[:exam].each do |e|
        univ.exams.build(subject: e.to_i)
      end
      if univ.save!
        redirect '/data/'
      end
    end
  end
end

get '/' do
  if session[:user_id]
    slim :content
  else
    slim :index
  end
end
