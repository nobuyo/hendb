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

enable :method_override
enable :sessions
set :session_secret, "My session secret", expire_after: 300

helpers do
  def link_to(url, txt=url)
    %Q(<a href="#{url}">#{txt}</a>)
  end

  def translate_to_subject(nb)
    %w(国語 数学 物理 化学 英語 TOEIC/TOEFL 専門 面接 小論文)[nb-1]
  end

  def selected_subject(nb,exams)
    exams.pluck('subject').to_a.include?(nb)
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
        user = User.new(email: Rack::Utils.escape_html(params[:email]))
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

before %r(/data/edit|new|create|patch|delete/?.*) do
  return status 403 unless @user.is_admin
end

namespace '/data' do
  get '/' do
    @data = Univ.all
    if @data.blank?
      @mess = "大学情報はまだありません。"
    end
    slim :'data/index'
  end

  get '/new' do
    slim :'data/new'
  end

  get '/edit/:id' do
    begin
      @data = Univ.find(params[:id])
      slim :'data/edit'
    rescue
      return status 404
    end
  end

  put '/patch' do
    univ = Univ.find(params[:id])
    univ.update_attributes!(
      name: Rack::Utils.escape_html(params[:name]),
      dept: Rack::Utils.escape_html(params[:dept]),
      pref: Rack::Utils.escape_html(params[:pref]),
      deviation_value: params[:deviation_value],
      exam_date: params[:exam_date],
      result_date: params[:result_date],
      affirmation_date: params[:affirmation_date],
      admit_units: params[:admit_units],
      document_url: Rack::Utils.escape_html(params[:document_url]),
      remark: Rack::Utils.escape_html(params[:remark]))
    univ.exams.destroy_all
    params[:exam].each do |e|
      univ.exams.build(subject: e.to_i)
    end
    univ.save!
    redirect "/data/univ/#{params[:id]}"
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
    else
      au = user.aspireUnivs.find_by(univ_id: params[:univ_id])
      au.destroy!
    end
    if params[:req_path] =~ %r(^/data/univ/.*)
      redirect "/data/univ/#{params[:univ_id]}"
    elsif params[:req_path] == '/data/bookmarks'
      redirect "/data/bookmarks"
    else
      redirect "/data/#data_#{params[:univ_id]}"
    end
  end

  get '/search' do
    query = Rack::Utils.escape_html(params[:q])
    @data = Univ.where('name like ? or pref like ? or dept like ?', "%#{query}%","%#{query}%","%#{query}%")
    if @data.blank?
      @mess = "検索条件に当てはまるものはまだありません。"
    end
    slim :'data/index'
  end

  get '/search/tags/:s' do
    @data = Univ.joins(:exams).where(exams: {subject: params[:s]})
    if @data.blank?
      @mess = "検索条件に当てはまるものはまだありません。"
    else
      @mess = "実施科目\"#{translate_to_subject(params[:s].to_i)}\"での検索結果"
    end
    slim :'data/index'
  end

  get '/univ/:id' do
    begin
      @univ = Univ.find(params[:id])
      slim :'data/univ'
    rescue
      return status 404
    end
  end

  post '/create' do
    unless Univ.exists?(name: params[:name])
      univ = Univ.new(
        name: Rack::Utils.escape_html(params[:name]),
        dept: Rack::Utils.escape_html(params[:dept]),
        pref: Rack::Utils.escape_html(params[:pref]),
        deviation_value: params[:deviation_value],
        exam_date: params[:exam_date],
        result_date: params[:result_date],
        affirmation_date: params[:affirmation_date],
        admit_units: params[:admit_units],
        document_url: Rack::Utils.escape_html(params[:document_url]),
        remark: Rack::Utils.escape_html(params[:remark]))
      params[:exam].each do |e|
        univ.exams.build(subject: e.to_i)
      end
      if univ.save!
        redirect '/data/'
      end
    end
  end

  delete '/delete/:id' do
    begin
      univ = Univ.find(params[:id])
      univ.destroy!
      redirect '/data/'
    rescue
      return status 404
    end
  end
end

namespace '/profile' do
  get '/mypage' do
    slim :'profile/mypage'
  end

  get '/edit/:id' do
    begin
      @user = User.find(params[:id])
      slim :'profile/edit'
    rescue
      return status 404
    end
  end

  put '/patch' do
    if params[:password] == params[:confirm_password]
      user = @user
      user.update!(email: Rack::Utils.escape_html(params[:email]))
      user.encrypt_password(params[:password])
      if user.save!
        session[:user_id] = user.id
        redirect "/profile/mypage"
      end
    else
      redirect "/profile/edit/#{params[:id]}"
    end
  end
end

get '/' do
  slim :index
end

error 403 do
  slim :'403'
end

not_found do
  slim :'404'
end
