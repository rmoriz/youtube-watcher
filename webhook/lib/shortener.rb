# frozen_string_literal: true

require 'singleton'
require 'date'
require 'digest'
require 'concurrent/timer_task'
require 'concurrent/hash' # JRuby etc.
require 'mqtt'
require 'json'

#:nodoc:
class Shortener
  include ::Singleton

  DEFAULT_EXPIRATION = 60 * 60 * 24 # 24 hours
  CLEANUP_EVERY = 60 * 60 # 1 hour

  attr_accessor :logger

  def initialize
    @data = Concurrent::Hash.new
    @logger = Logger.new(STDERR)
  end

  def dump
    @data
  end

  def add(url, public_url, expiration = nil)
    expiration ||= Time.new + DEFAULT_EXPIRATION

    key = Digest::SHA256.base64digest(url).gsub(/\W/, '')[0, 12]

    @data[key] = {
      'key' => key,
      'short' => url_for_key(key),
      'url' => url,
      'public_url' => public_url,
      'expiration' => expiration
    }

    logger.debug "shortener created: #{key} for URL: #{url} [#{public_url}]"
    @data[key]
  end

  def exists?(key)
    !lookup(key).nil?
  end

  def public_url_exists?(public_url)
    !@data.select { |key, data| data['public_url'] == public_url }.empty?
  end

  def lookup(key)
    @data.dig(key)
  end

  def roomservice
    task = Concurrent::TimerTask.new(
      run_now: true,
      execution_interval: CLEANUP_EVERY
    ) do
      Shortener.instance.cleanup
    end

    task.execute
  end

  def mqtt_service
    Thread.new do
      client = MQTT::Client.connect(mqtt_dsn)
      client.subscribe('SHORTENER_REQUEST')

      @logger.debug "mqtt service started #{mqtt_dsn}"

      client.get do |_topic, json_message|
        message = JSON.parse(json_message)
        payload = Shortener.instance.add(
          message['url'],
          message['public_url'],
          message['expiration']
        )

        MQTT::Client.connect(mqtt_dsn) do |c|
          c.publish('SHORTENER_RESPONSE', payload.to_json)
        end
      end
    end
  end

  protected

  def url_for_key(key)
    uri = URI.parse(ENV['SHORTENER_ENDPOINT'])
    URI.parse(
      uri.scheme + '://' + uri.host + ':' + uri.port.to_s +
      '/' + key
    )
  end

  def mqtt_dsn
    'mqtts://' +
      ENV['MQTT_USER'] + ':' +
      ENV['MQTT_PASSWORD'] + '@' +
      ENV['MQTT_SERVER']
  end

  def cleanup
    @logger.debug 'shortener cleanup started'
    @data.each do |key, data|
      if data['expiration'] && data['expiration'] <= now
        @logger.info "shortener expired: #{key} => " + @data[key]['url']
        @data.delete(key)
      end
    end
  end
end
