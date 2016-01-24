#!/Users/carecloud/.rvm/rubies/ruby-2.1.2/bin/ruby
require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'omniauth-twitter'
require 'data_mapper'
require 'twitter'
require 'json'
require 'erb'

$Tweets = {}
$Unique_Earliest_Campaigns = {}


client = Twitter::REST::Client.new do |config|
  config.consumer_key = 'DCfSzu7Y4NTCqqEMC96H0X21X'
  config.consumer_secret = '9ppSzdNgrBsmbyGG1j8KbkLMaCZ7h1FVh5CaBfQmjTUCuwu6QN'
  config.access_token = '260634042-2xdwuPbH7XlB6bN67DFdL6Su85Tpjya2ZHjBCSpg'
  config.access_token_secret = 'cSj8X8kK6gAHXHIM41wj9PmotY3vKrtT8kFlVSHM0dIMK'
end

get '/all_tweets' do
  a = 0
  client.search("#tweetybitcoin", result_type: "recent").take(10).collect do |tweet|
    a = a+1
    capmaign_name = ''
    tweet.text.scan(/#.\w{1,}/).each {|match| capmaign_name = match unless match == "#tweetybitcoin"}
    if tweet.media.empty? 
      image = "img/tweetybitcoin.jpg"
    else 
      image = tweet.media[0].media_url
    end
    $Tweets[a]={
      "id"=>tweet.id,
      "tweet.user.screen_name"=>tweet.user.screen_name,
      "tweet.user.followers_count"=>tweet.user.followers_count,
      "tweet.user.statuses_count"=>tweet.user.statuses_count,
      "tweet.text"=>tweet.text,
      "tweet.retweet_count"=>tweet.retweet_count,
      "tweet.favorite_count"=>tweet.favorite_count,
      "capmaign_name"=>capmaign_name,
      "tweet.media_url"=>image
    }
  end
  "#{$Tweets.to_s}"
end

get '/myCampaigns' do
  #$Tweets[1]["tweet.user.screen_name"]
  $Unique_Earliest_Campaigns[1] = $Tweets[1]
  unique_index = 1
  $Tweets.each do |index,tweet|
    all_unique_campaign_names = []
    #get all names of campaigns in cureent state of $Unique_Earliest_Campaigns:
    $Unique_Earliest_Campaigns.each {|index,camp| all_unique_campaign_names << camp["capmaign_name"]}
    #compare with next one in $Tweets:
    if all_unique_campaign_names.include? tweet["capmaign_name"] 
      #calculate if already stored capmaign_name id is bigger than newly found. In this case - replace:
      if $Unique_Earliest_Campaigns[unique_index]["id"]>tweet["id"]
        puts "replacing stored tweet with newer: #{tweet.to_s}"
        $Unique_Earliest_Campaigns.each {|index,camp| 
          if camp["capmaign_name"] == tweet["capmaign_name"] 
            $Unique_Earliest_Campaigns[index] = tweet
          end 
          } 
        $Unique_Earliest_Campaigns.each {|index,camp| print camp["id"]}
      else
        puts "skipping #{tweet.to_s}"
        $Unique_Earliest_Campaigns.each {|index,camp| print camp["id"]}
      end
    else 
      puts "adding tweet #{tweet.to_s}"
      unique_index = unique_index + 1
      $Unique_Earliest_Campaigns[unique_index]=tweet
      $Unique_Earliest_Campaigns.each {|index,camp| print camp["id"]}
    end
  end
  erb :campaigns_erb
end

get '/tweets' do
  a = 0
  @Tweets = {}
  client.search("#tweetybitcoin", result_type: "recent").take(10).collect do |tweet|
    a = a+1
    capmaign_name = ''
    tweet.text.scan(/#.\w{1,}/).each {|match| capmaign_name = match unless match == "#tweetybitcoin"}
    @Tweets[a]={"tweet.user.screen_name"=>tweet.user.screen_name,
      "tweet.user.followers_count"=>tweet.user.followers_count,
      "tweet.user.statuses_count"=>tweet.user.statuses_count,
      "tweet.text"=>tweet.text,
      "tweet.retweet_count"=>tweet.retweet_count,
      "tweet.favorite_count"=>tweet.favorite_count,
      "capmaign_name"=>capmaign_name
    }
  end
  @Tweets.to_s
end


use OmniAuth::Builder do
  provider :twitter, 'DCfSzu7Y4NTCqqEMC96H0X21X', '9ppSzdNgrBsmbyGG1j8KbkLMaCZ7h1FVh5CaBfQmjTUCuwu6QN'
end


#DB
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class Campaigns
  include DataMapper::Resource
  property :id,           Serial
  property :hashtag,      String, :required => true
  property :author,       String, :required => true
end
DataMapper.finalize
#Campaigns.create(hashtag: "Volvo2016", author: "SergiiMiami")

get '/startCampaign' do
  puts ""
end

get '/signin' do
  redirect to("/auth/twitter")
end

get '/auth/twitter/callback' do
  env['omniauth.auth'] ? session[session[:candidate].to_sym] = true : halt(401,'Not Authorized')
  #logic to find out if Company or User
  #output = ''
  #env.each { |n,v| output << n.to_s; output << ": "; output << v.to_s; output << "; " }
  #output
#  "<h1>Hi #{env['omniauth.auth']['info']['nickname']}!</h1><img src='#{env['omniauth.auth']['info']['image']}'>"
end




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

#get '/myCampaings' do
#  "Hello, myCampaings. You are #{role} <br/> <a href='/changeRoleToUser'> ChangeRole </a>"
#end

get '/logout' do
  session[:isUser] = false
  session[:isCompany] = false
  "You are logging out"
end

#get '/startCampaign' do
#  session[:candidate] = :isCompany
#  if (session[:isUser] or session[:isCompany])
#  	redirect to("/myCampaings")
#  else
#  	redirect to("/auth/twitter")
#  end
#end

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
