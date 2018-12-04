#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'logger'

require_relative 'lib/shortener'
require_relative 'lib/subscription_manager'
require_relative 'lib/websub'

threads = []

# Timer task to renew WebSub subscriptions
threads << Thread.new do
  sm = SubscriptionManager.instance
  sm.logger = Logger.new(STDERR)
  sleep 5
  sm.start!(ENV['CHANNEL_IDS'])
end

# cleanup of expired short urls
threads << Thread.new do
  Shortener.instance.roomservice
end

# puma running Sinatra
threads << Thread.new do
  run Websub
end

# mqtt client thread that creates new shortener
Shortener.instance.mqtt_service

threads.each(&:join)
