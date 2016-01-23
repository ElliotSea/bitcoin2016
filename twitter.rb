#!/Users/carecloud/.rvm/rubies/ruby-2.1.2/bin/ruby
require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'omniauth-twitter'
require 'data_mapper'
require 'twitter'
require 'json'

client = Twitter::REST::Client.new do |config|
  config.consumer_key = 'DCfSzu7Y4NTCqqEMC96H0X21X'
  config.consumer_secret = '9ppSzdNgrBsmbyGG1j8KbkLMaCZ7h1FVh5CaBfQmjTUCuwu6QN'
  config.access_token = '260634042-2xdwuPbH7XlB6bN67DFdL6Su85Tpjya2ZHjBCSpg'
  config.access_token_secret = 'cSj8X8kK6gAHXHIM41wj9PmotY3vKrtT8kFlVSHM0dIMK'
end

get '/tweets' do
  5.times { puts '-------' }
  #tw = client.status('676148707176423424')
  #puts "Text: #{tw.text}"
  #tw = client.search("#tweetybitcoin")
  #puts tw.to_h
  client.search("#MiaBitcoinHack #tweetybitcoin", result_type: "recent").take(1).collect do |tweet|
  puts tweet.to_h
  "#{tweet.user.screen_name}: #{tweet.text}"
  end
  #puts tw
end


use OmniAuth::Builder do
  provider :twitter, 'DCfSzu7Y4NTCqqEMC96H0X21X', '9ppSzdNgrBsmbyGG1j8KbkLMaCZ7h1FVh5CaBfQmjTUCuwu6QN'
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class Campaigns
  include DataMapper::Resource
  property :id,           Serial
  property :hashtag,      String, :required => true
  property :author,       String, :required => true
end
DataMapper.finalize
#Campaigns.create(hashtag: "Volvo2016", author: "SergiiMiami")

configure do
  enable :sessions
end

helpers do
  def isUser?
    session[:isUser]
  end
  def isCompany?
    session[:isCompany]
  end
  def role
  	if session[:isUser]
  		user_role = "User"
  	elsif session[:isCompany]
  		user_role = "Company"
  	else user_role = "Else"
  	end
  	user_role 
  end
end

get '/' do
  'Hello, everyone'
end

get '/myDashboard' do
  "Hello, myDashboard. You are #{role}"
end

get '/myCampaings' do
  "Hello, myCampaings. You are #{role} <br/> <a href='/changeRoleToUser'> ChangeRole </a>"
end

get '/logout' do
  session[:isUser] = false
  session[:isCompany] = false
  "You are logging out"
end

get '/startCampaign' do
  session[:candidate] = :isCompany
  if (session[:isUser] or session[:isCompany])
  	redirect to("/myCampaings")
  else
  	redirect to("/auth/twitter")
  end
end

get '/earn' do
session[:candidate] = :isUser
  if (session[:isUser] or session[:isCompany])
  	redirect to("/myDashboard")
  else
  	redirect to("/auth/twitter")
  end
end

get '/changeRoleToUser' do
	session[:isCompany] = false
	session[:isUser] = true
  	redirect to("/myDashboard")	
end

get '/auth/twitter/callback' do
  env['omniauth.auth'] ? session[session[:candidate].to_sym] = true : halt(401,'Not Authorized')
  #logic to find out if Company or User
  output = ''
  env.each { |n,v| output << n.to_s; output << ": "; output << v.to_s; output << "; " }
  output
#  "<h1>Hi #{env['omniauth.auth']['info']['nickname']}!</h1><img src='#{env['omniauth.auth']['info']['image']}'>"
end
