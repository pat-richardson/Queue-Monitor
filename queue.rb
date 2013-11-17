require 'rubygems'
require 'active_support/core_ext/numeric/time'
require 'bundler/setup'
require 'json'
require 'httparty'
require 'hipchat-api'
require_relative 'credentials'
    
class Queue_Monitor
	include Credentials
	def handle_data
		auth = {:username => USERNAME, :password => PASSWORD} #uses username and password in Credentials module
		options = { :basic_auth => auth }
		queue_activity = HTTParty.get( "https://breadcrumb.zendesk.com/api/v2/channels/voice/stats/current_queue_activity.json", options)

		call_volume = JSON.parse(queue_activity.body)["current_queue_activity"]
		puts "Calls Waiting: #{call_volume["calls_waiting"]}"
		puts "Longest Wait Time: #{Float((call_volume["longest_wait_time"].to_i)/60).round(2)}"

		if call_volume["calls_waiting"] > 2 || call_volume["longest_wait_time"] >= 300.0
			message = "@all There are #{call_volume["calls_waiting"]} calls in the queue. Longest wait time is #{Float((call_volume["longest_wait_time"].to_i)/60).round(2)} minute(s)."
			robot = HipChat::API.new(HTOKEN) #uses token in Credentials module
			puts robot.rooms_message(ROOMID, "HipChat Robot", message, notify = 1, color = 'red', message_format = 'text') #uses room id set in credentials module
			sleep(3.minutes) 	
		end
	end

	def app_controller
		while true
			handle_data
			puts Time.now
			puts
			sleep(30)
			app_controller
		end
	end
end

robot = Queue_Monitor.new
robot.app_controller


