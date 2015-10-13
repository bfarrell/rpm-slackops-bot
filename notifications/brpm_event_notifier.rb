#!/usr/bin/env ruby
require 'rubygems'
require 'torquebox'
require 'torquebox-messaging'
require 'xmlsimple'
require 'rest-client'
require 'json'

host = ENV["EVENT_HANDLER_MESSAGING_BRPM_HOST"]
port = ENV["EVENT_HANDLER_MESSAGING_PORT"]
username = ENV["EVENT_HANDLER_MESSAGING_USERNAME"]
password = ENV["EVENT_HANDLER_MESSAGING_PASSWORD"]

class MessagingProcessor < TorqueBox::Messaging::MessageProcessor

  MESSAGING_PATH = '/topics/messaging/brpm_event_queue'

  def initialize(host, port, username, password)
    print "Initializing the message processor...\n"
    @destination = TorqueBox::Messaging::Topic.new(
        MESSAGING_PATH,
        :host => host,
        :port => port,
        :username => username,
        :password => password
    )

    @slack_token = ENV["EVENT_HANDLER_SLACK_TOKEN"]
    @slack_channel = ENV["EVENT_HANDLER_SLACK_CHANNEL"]
    @brpm_url = ENV["EVENT_HANDLER_BRPM_URL"]
  end

  def run
    begin
      xml = "<root>#{@destination.receive}</root>"

      print "Processing new event...\n"
      print xml + "\n" if ENV["EVENT_HANDLER_LOG_EVENT"]=="1"

      event = XmlSimple.xml_in(xml)

      if event.has_key?("request")
        print "The event is for a request #{event["event"][0]}...\n"
        if event["event"][0] == "create"
          request = event["request"].find { |item| item["type"] == "new" }

          message = "Request <#{@brpm_url}/brpm/requests/#{(request["id"][0]["content"].to_i + 1000).to_s}|#{request["name"][0]}> created"
        elsif event["event"][0] == "update"
          request_old_state = event["request"].find { |item| item["type"] == "old" }
          request_new_state = event["request"].find { |item| item["type"] == "new" }

          if request_old_state["aasm-state"][0] != request_new_state["aasm-state"][0] or request_new_state["aasm-state"][0] == "complete" #TODO bug when a request is moved to complete the old state is also reported as complete
            message = "Request <#{@brpm_url}/brpm/requests/#{(request_new_state["id"][0]["content"].to_i + 1000).to_s}|#{request_new_state["name"][0]}> moved from state '#{request_old_state["aasm-state"][0]}' to state '#{request_new_state["aasm-state"][0]}'"
          end
        end
      end

      if message
        payload = {}
        payload["channel"] = "##{@slack_channel}"
        payload["text"] = message

        rest_params = {}
        rest_params[:url] = "https://hooks.slack.com/services/#{@slack_token}"
        rest_params[:method] = "post"
        rest_params[:payload] = payload.to_json

        print "message: #{message}\n"
        print "Sending the message to slack...\n"
        response = RestClient::Request.new(rest_params).execute
        print response + "\n"
      end
    rescue Exception => e
      print e.message
      print "\n\t" + e.backtrace.join("\n\t") + "\n"
    end
  end
end

begin
  consumer = MessagingProcessor.new(host, port, username, password)
  print "Starting to listen for events ...\n"
  loop do
    consumer.run
  end

rescue Exception => e
  print e.message
  print "\n\t" + e.backtrace.join("\n\t") + "\n"

  raise e
end
