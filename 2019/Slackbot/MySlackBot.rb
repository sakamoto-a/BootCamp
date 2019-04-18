# coding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__))

BASE_URL = "http://api.openweathermap.org/data/2.5/forecast"

require 'sinatra'
require 'SlackBot'
require 'json'
require 'open-uri'
require 'date'

class MySlackBot < SlackBot
  # cool code goes here
  def say_message(message)
    return message.split("@sakabot ")[1].split("と言って")[0] 
  end
  
  def weather(message)
    city_name = message.split("@sakabot ")[1].split("の天気")[0]
    if city_name.include?("時間後の") then time = city_name.split("時間後の")[0].to_i
      now = Time.now
      if (117-now.hour) < time then
        time_limit = (117-now.hour).to_s
        return ("その時刻の予報は存在していません．" + time_limit + "時間以内で指定してください")
      elsif time < 0 then
        time_limit = (117-now.hour).to_s
        return ("不正な時刻です．" + time_limit + "以下の自然数で指定してください")
      else
        num = time/3       
        city_name = city_name.split("時間後の")[1]
      end
    else num = 0
    end
    begin response = open(BASE_URL + "?q=" + city_name +",jp&APPID=" + @config["open_weather_map_api"])  
    rescue => e
      return "存在しない地名です．ローマ字で日本の地名を入力してください"
    end
    weather_data = JSON.parse(response.read)
    return weather_data["list"][2+num]["weather"][0]["description"]
  end
  
  def help
    return "こんにちはsakabotです\n〜と言って：〜と発言します\n（◯時間後の）＜地名＞の天気：◯時間後の＜地名＞の天気をお知らせします"
  end
end



slackbot = MySlackBot.new

set :environment, :production

get '/' do
  "SlackBot Server"
end

post '/slack' do
  content_type :json
  if params[:text].include?("と言って") then params[:text] = slackbot.say_message(params[:text])
  elsif params[:text].include?("の天気") then params[:text] = slackbot.weather(params[:text])
  else params[:text] = slackbot.help
  end
  slackbot.post_message(params[:text], username: "sakabot")
end
