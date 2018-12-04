# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'concurrent/timer_task'
require 'singleton'

#:nodoc:
class SubscriptionManager
  include Singleton

  DEFAULT_LEASE_SECONDS = 86_400 # 1 day

  attr_accessor :vcs
  attr_accessor :logger

  attr_reader   :callback_url
  attr_reader   :hmac_secret
  attr_reader   :lease_seconds
  attr_accessor :accepted_topics

  def initialize
    @callback_url  = ENV['WEBSUB_SUBSCRIBER_CALLBACK']
    # TODO
    @hmac_secret   = ENV['HMAC_SECRET']

    @lease_seconds = ENV['WEBSUB_LEASE_SECONDS'] || DEFAULT_LEASE_SECONDS
  end

  def start!(channel_ids_string)
    vendorize_channels(channel_ids_string.split(','))
    create_accepted_topics_list

    logger.info "SubscriptionManager started: #{vcs}"

    task = Concurrent::TimerTask.new(
      run_now: true,
      execution_interval: lease_seconds,
      timeout_interval: 60
    ) do
      manage(:subscribe)
    end
    task.execute
  end

  protected

  def vendorize_channels(channel_ids)
    @vcs = {}

    channel_ids.each do |channel|
      vendor, id = channel.split(':')
      @vcs[vendor] ||= []
      @vcs[vendor] << id
    end
  end

  def manage(action)
    @vcs.keys.each do |vendor|
      case vendor
      when 'yt'
        manage_youtube_channels(@vcs[vendor], action)
      else
        logger.info "Vendor #{vendor} not supported"
      end
    end
  end

  def manage_youtube_channels(channels, action = :subscribe)
    uri = URI.parse 'https://pubsubhubbub.appspot.com/subscribe'
    http = Net::HTTP.new(
      uri.hostname, uri.port
    )

    http.use_ssl = (uri.scheme == 'https')
    http.set_debug_output(logger)

    channels.each do |channel_id|
      logger.debug "subscribing YouTube channel: #{channel_id}…"

      request = Net::HTTP::Post.new(uri)
      set_form_data(request, channel_id, action)
      logger.debug "Request: #{request.inspect}"

      response = http.request(request)

      logger.debug "Response code: #{response.code}"
      logger.debug "Response body: #{response.body}"
    end

    http.finish if http.started?
  end

  def set_form_data(request, channel_id, action)
    request.set_form_data(
      'hub.callback' => callback_url,
      'hub.mode' => action.to_s,
      'hub.topic' => format(
        'https://www.youtube.com/xml/feeds/videos.xml?channel_id=%{channel_id}',
        channel_id: channel_id
      ),
      'hub.lease_seconds' => lease_seconds,
      'hub.secret' => hmac_secret
    )
    request
  end

  def create_accepted_topics_list
    topics = []
    @vcs.keys.each do |vendor|
      case vendor
      when 'yt'
        topics += @vcs['yt'].map do |channel_id|
          format(
            'https://www.youtube.com/xml/feeds/videos.xml?channel_id=%{channel_id}',
            channel_id: channel_id
          )
        end
      else
        logger.info "Vendor #{vendor} not supported"
      end
    end

    @accepted_topics = topics
    @accepted_topics
  end
end
