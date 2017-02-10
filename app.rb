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

before %r{/$|/auth/*} do
  case session[:flash]
  when 1 then
    @role = 'danger'
    @alert = '確認用パスワードが一致しません'
  when 2 then
    @role = 'danger'
    @alert = 'メールアドレスまたはパスワードが間違っています'
  when 3 then
    @role = 'danger'
    @alert = 'すでに登録されているメールアドレスです'
  when 4 then
    @role = 'info'
    @alert = 'ログインしました'
  when 5 then
    @role = 'info'
    @alert = '登録しました'
  end
  session[:flash] = 0
end

get '/' do
  slim :index
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
          session[:flash] = 5
          redirect "/"
        end
      else
        session[:flash] = 1
        redirect '/auth/sign_up'
      end
    else
      session[:flash] = 3
      redirect "/auth/sign_in"
    end
  end

  post '/authenticate' do
    user = User.auth(params[:email], params[:password])
    unless user.nil?
      session[:user_id] = user.id
      session[:flash] = 4
      redirect '/'
    else
      session[:flash] = 2
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
    session[:flash] = 1
    redirect "/auth/sign_in"
  end
end

before '/data/*' do
  case session[:flash]
  when 1 then
    @role = 'danger'
    @alert = 'ログインしてください'
  when 2 then
    @role = 'info'
    @alert = '変更を保存しました'
  when 3 then
    @role = 'danger'
    @alert = '変更の保存に失敗しました'
  when 4 then
    @role = 'info'
    @alert = '保存しました'
  when 5 then
    @role = 'danger'
    @alert = '保存に失敗しました'
  when 6 then
    @role = 'info'
    @alert = '削除しました'
  end
  session[:flash] = 0
end

before %r(/data/edit|new|create|patch|delete/?.*) do
  return status 403 unless @user.is_admin
end

namespace '/data' do
  get '/' do
    if %w(exam_date affirmation_date deviation_value).include?(params[:sort])
      @data = Univ.all.order(params[:sort])
    else
      @data = Univ.all
    end
    if @data.blank?
      @mess = "大学情報はまだありません。"
    end
    slim :'data/index'
  end

  get '/new' do
    slim :'data/new'
  end

  get %r{/edit/([\d]+)} do |id|
    begin
      @data = Univ.find(id)
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
    begin
      univ.save!
      session[:flash] = 2
      redirect "/data/univ/#{params[:id]}"
    rescue
      session[:flash] = 3
      redirect "/data/edit/#{params[:id]}"
    end
  end

  get '/bookmarks' do
    if %w(exam_date affirmation_date deviation_value).include?(params[:sort])
      @data = @user.univs.order(params[:sort])
    else
      @data = @user.univs
    end

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

  get %r{/search/tags/([\d]+)} do |s|
    @data = Univ.joins(:exams).where(exams: {subject: s})
    if @data.blank?
      @mess = "検索条件に当てはまるものはまだありません。"
    else
      @mess = "実施科目\"#{translate_to_subject(params[:s].to_i)}\"での検索結果"
    end
    slim :'data/index'
  end

  get %r{/univ/([\d]+)} do |id|
    begin
      @univ = Univ.find(id)
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
      begin
        univ.save!
        session[:flash] = 4
        redirect '/data/'
      rescue
        session[:flash] = 5
      end
    end
  end

  delete %r{/delete/([\d]+)} do |id|
    begin
      univ = Univ.find(id)
      univ.destroy!
      session[:flash] = 6
      redirect '/data/'
    rescue
      return status 404
    end
  end
end

before '/profile/*' do
  case session[:flash]
  when 1 then
    @role = 'info'
    @alert = '変更を保存しました'
  when 2 then
    @role = 'danger'
    @alert = '変更の保存に失敗しました'
  when 3 then
    @role = 'danger'
    @alert = '確認用パスワードが一致しません'
  end
  session[:flash] = 0
end

namespace '/profile' do
  get '/mypage' do
    slim :'profile/mypage'
  end

  before %r{/edit/([\d]+)} do |id|
    return status 403 unless params[:id].to_i == id
  end

  get %r{/edit/([\d]+)} do |id|
    begin
      @data = User.find(id)
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
      begin
        user.save!
        session[:user_id] = user.id
        session[:flash] = 1
        redirect "/profile/mypage"
      rescue
        session[:flash] = 2
        redirect "/profile/edit/#{params[:id]}"
      end
    else
      session[:flash] = 3
      redirect "/profile/edit/#{params[:id]}"
    end
  end
end

error 403 do
  slim :'403'
end

not_found do
  slim :'404'
end
