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
    @brpm_token = ENV["EVENT_HANDLER_BRPM_TOKEN"]
  end

  def get_request_details request_id
    rest_params = {}
    rest_params[:url] = "#{@brpm_url}/brpm/v1/requests/#{request_id}?token=#{@brpm_token}"
    rest_params[:method] = "get"
    rest_params.merge!({:headers => { :accept => :json, :content_type => :json }})

    response = RestClient::Request.new(rest_params).execute
    JSON.parse(response)
  end

  def get_step_details step_id
    rest_params = {}
    rest_params[:url] = "#{@brpm_url}/brpm/v1/steps/#{step_id}?token=#{@brpm_token}"
    rest_params[:method] = "get"
    rest_params.merge!({:headers => { :accept => :json, :content_type => :json }})

    response = RestClient::Request.new(rest_params).execute
    JSON.parse(response)
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
          request_details = get_request_details(request["id"][0]["content"])

          message = "<#{@brpm_url}/brpm/apps/#{request_details["apps"][0]["name"]}|#{request_details["apps"][0]["name"]}> \>\> <#{@brpm_url}/brpm/requests/#{(request["id"][0]["content"].to_i + 1000).to_s}|#{request["name"][0]}>: _created_"
        elsif event["event"][0] == "update"
          request_old_state = event["request"].find { |item| item["type"] == "old" }
          request_new_state = event["request"].find { |item| item["type"] == "new" }
          request_details = get_request_details(request_new_state["id"][0]["content"])

          if request_old_state["aasm-state"][0] != request_new_state["aasm-state"][0] or request_new_state["aasm-state"][0] == "complete" #TODO bug when a request is moved to complete the old state is also reported as complete
            message = "<#{@brpm_url}/brpm/apps/#{request_details["apps"][0]["name"]}|#{request_details["apps"][0]["name"]}> \>\> <#{@brpm_url}/brpm/requests/#{(request_new_state["id"][0]["content"].to_i + 1000).to_s}|#{request_new_state["name"][0]}>: _#{request_old_state["aasm-state"][0]}_ =\> _#{request_new_state["aasm-state"][0]}_"
          end
        end
      elsif event.has_key?("step")
        print "The event is for a step #{event["event"][0]}...\n"
        if event["event"][0] == "create"
          step = event["step"].find { |item| item["type"] == "new" }
          step_details = get_step_details(step["id"][0]["content"])

          message = "<#{@brpm_url}/brpm/apps/#{step_details["installed_component"]["app"]["name"]}|#{step_details["installed_component"]["app"]["name"]}> \>\> <#{@brpm_url}/brpm/requests/#{(step_details["request"]["id"].to_i + 1000).to_s}|#{step_details["request"]["name"]}> \>\> *#{step_details["name"]}*: _created_"
        elsif event["event"][0] == "update"
          step_old_state = event["step"].find { |item| item["type"] == "old" }
          step_new_state = event["step"].find { |item| item["type"] == "new" }
          step_details = get_step_details(step_new_state["id"][0]["content"])

          if step_old_state["aasm-state"][0] != step_new_state["aasm-state"][0] or step_new_state["aasm-state"][0] == "complete" #TODO bug when a request is moved to complete the old state is also reported as complete
            message = "<#{@brpm_url}/brpm/apps/#{step_details["installed_component"]["app"]["name"]}|#{step_details["installed_component"]["app"]["name"]}> \>\> <#{@brpm_url}/brpm/requests/#{(step_details["request"]["id"].to_i + 1000).to_s}|#{step_details["request"]["name"]}> \>\> *#{step_details["name"]}*: _#{step_old_state["aasm-state"][0]}_ =\> _#{step_new_state["aasm-state"][0]}_"
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
