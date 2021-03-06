require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
  @db = SQLite3::Database.new 'leprosorium.db'
  @db.results_as_hash = true
end

before do 
  init_db
end

configure do 
  init_db
  @db.execute 'CREATE TABLE IF NOT EXISTS Posts
   (
     id integer PRIMARY KEY AUTOINCREMENT,
     created_date date,
     content text
   )'

   @db.execute 'CREATE TABLE IF NOT EXISTS Comments
   (
     id integer PRIMARY KEY AUTOINCREMENT,
     created_date date,
     content text,
     post_id integer
   )'
end

get '/' do
  @results = @db.execute 'select * from Posts order by id desc'

  erb :index
end

get '/new' do
  erb :new
end

post '/new' do
  content = params[:content]

  if content.length <= 0
    @error = "Type post text"
    return erb :new
  end 

  @db.execute 'insert into Posts (content, created_date) values ( ?, datetime())', [content]

  redirect to '/'
end

get '/details/:post_id'  do
  post_id = params[:post_id]

  results = @db.execute 'select * from Posts where id = ?', [post_id]
  @row = results[0]

  @comments = @db.execute 'select * from Comments where post_id = ? order by id', [post_id]

  erb :details  
end

post '/details/:post_id'  do
  post_id = params[:post_id]
  content = params[:content]

  @db.execute 'insert into Comments 
    (
      content, 
      created_date, 
      post_id
    ) 
    values 
    (
       ?, 
       datetime(),
       ?
     )', [content, post_id]

  redirect to ('/details/' + post_id)

end

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'
end

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']
  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
end
