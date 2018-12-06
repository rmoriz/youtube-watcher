#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'net/http'
require 'logger'
require 'json'
require 'uri'

require 'mqtt'

require_relative 'lib/extractor'
require_relative 'lib/stream_reader'
require_relative 'lib/shortener'
require_relative 'lib/pusher'

$stdout.sync = true

def mqtt_dsn
  'mqtts://' +
    ENV['MQTT_USER'] + ':' +
    ENV['MQTT_PASSWORD'] + '@' +
    ENV['MQTT_SERVER']
end

download_directory = ENV['DOWNLOAD_DIRECTORY'] || '/data/downloads'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
logger.info 'starting'

threads = []

threads << Thread.new do
  client = MQTT::Client.connect(mqtt_dsn)
  client.subscribe('VIDEO')

  client.get do |_topic, json_message|
    message = JSON.parse json_message
    logger.debug "message: #{message}"

    extractor = Extractor.new(
      logger: logger,
      message: message,
      download_directory: download_directory
    )

    logger.debug extractor.url

    Thread.new do
      # prefix is vlc:// which opens VLC with the stream on iOS after 2 taps
      # will send shorten requet via MQTT
      shortend_uri = Shortener.shorten_with_prefix(extractor.url, message['public_url'])
    end

    Thread.new do
      extractor.capture_stream
    end
  end
end

threads << Thread.new do
  logger.info 'waiting for SHORTENER_RESPONSE'

  client = MQTT::Client.connect(mqtt_dsn)
  client.subscribe('SHORTENER_RESPONSE')
  client.get do |_topic, json_message|
    logger.info 'got SHORTENER_RESPONSE'
    message = JSON.parse json_message
    logger.info message

    Pusher.deliver(message['short'].to_s, message['short'].to_s)
  end
end

threads.each(&:join)
