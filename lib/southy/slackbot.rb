require 'slack-ruby-client'

module Southy
  class Slackbot
    def initialize(config, travel_agent)
      @config = config
      @agent = travel_agent

      Slack.configure do |slack_cfg|
        slack_cfg.token = @config.slack_api_token
      end

    end

    def run
      @webclient = Slack::Web::Client.new
      auth = @webclient.auth_test
      if auth['ok']
        puts "Slackbot is active!"
      else
        puts "Slackbot is doomed :-("
        return
      end

      client = Slack::RealTime::Client.new

      client.on :message do |data|
        next if data['user'] == 'U0HM6QX8Q' # this is Mr. Southy!
        send_msg = Proc.new { |msg| client.message channel: data['channel'], text: msg }
        method = data['text'].split(' ').first
        args = data['text'].split(' ')[1..-1]
        send method, data, args, &send_msg
      end

      client.start!
    rescue => e
      puts e.message
      puts e.backtrace
    end

    def method_missing(name, *args)
      puts "No method found for: #{name}"
      pp args[0]
    end

    def user_profile(data)
      id = data['user']
      res = @webclient.users_info user: id
      return {} unless res['ok']
      profile = res['user']['profile']
      { id: id, first_name: profile['first_name'], last_name: profile['last_name'], email: profile['email'] }
    end

    def hello(data, args, &send)
      profile = user_profile data
      send.call "hello #{profile[:first_name]}"
    end

    def list(data, args, &send)
      flights = nil
      if args == ['all']
        flights = @config.upcoming
        send.call "Upcoming flights:"
      else
        profile = user_profile data
        flights = @config.upcoming.select { |f| f.email == profile[:email] }
        send.call "Upcoming flights for #{profile[:email]}:"
      end
      out = '```'
      if flights.length > 0
        flights.each { |f| out += f.to_s(short: true) + "\n" }
      else
        out += 'No upcoming flights.'
      end
      out += '```'
      send.call out
    end

    def add(data, args, &send)
      args.tap do |(conf, fname, lname, email)|
        unless fname and lname
          profile = user_profile data
          fname = profile[:first_name]
          lname = profile[:last_name]
          email = profile[:email]
        end
        return ( send.call "You didn't enter a confirmation number!" ) unless conf
        if match = email.match(/^<mailto:(.*)\|/)
          email = match.captures[0]
        end
        @config.add conf, fname, lname, email
        sleep 3
        list data, '', &send
      end
    end

    def remove(data, args, &send)
      args.tap do |(conf)|
        return ( send.call "You didn't enter a confirmation number!" ) unless conf
        @config.remove conf
        list data, '', &send
      end
    end
  end
end