#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'net/http'
require 'logger'
require 'json'
require 'uri'

require 'mqtt'

require_relative 'lib/downloader'
require_relative 'lib/stream_reader'

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
  logger.info 'waiting for VIDEO'

  client.get do |_topic, json_message|
    message = JSON.parse json_message
    logger.debug "message: #{message}"

    Thread.new do
      dl = Downloader.new(
        logger: logger,
        message: message,
        download_directory: download_directory
      )
      dl.capture_stream
    end
  end
end

threads.each(&:join)
