# frozen_string_literal: true

require 'feedjira'
require 'mqtt'
require 'sinatra/base'
require 'sinatra/multi_route'
require 'sinatra/custom_logger'
require 'logger'

#:nodoc:
class Websub < Sinatra::Base
  register Sinatra::MultiRoute
  helpers Sinatra::CustomLogger

  configure :development, :production do
    set :logger, Logger.new(STDERR)
    use Rack::CommonLogger, logger
  end

  helpers do
    def mqtt_dsn
      'mqtts://' +
        ENV['MQTT_USER'] + ':' +
        ENV['MQTT_PASSWORD'] + '@' +
        ENV['MQTT_SERVER']
    end

    # TODO
    # def verify_signature(payload_body)
    #   signature = 'sha1=' +
    #                OpenSSL::HMAC.hexdigest(
    #                  OpenSSL::Digest.new('sha1'),
    #                  ENV['SECRET_TOKEN'], payload_body
    #                )
    #   return halt 500,
    #      "Signatures didn't match!" unless Rack::Utils.secure_compare(
    #        signature, request.env['HTTP_X_HUB_SIGNATURE']
    #      )
    # end
  end

  # see:
  #   - https://developers.google.com/youtube/v3/guides/push_notifications
  #   - https://pubsubhubbub.appspot.com/subscribe
  #
  # Rossmann live: UC6nZlvfz4YWoBWbjiaYJA3g
  # https://www.youtube.com/xml/feeds/videos.xml?channel_id=UC6nZlvfz4YWoBWbjiaYJA3g
  route :get, :post, '/websub' do
    body = request.body.read
    logger.info "incoming headers: #{headers}"
    logger.info "incoming body: #{body}"

    if body && !body.empty?
      begin
        feed = Feedjira::Feed.parse(body)

        if !feed.entries.empty?
          entry = feed.entries.first.to_h

          # preserve public url, allows us to filter duplicates.
          entry['public_url'] = entry['url']

          logger.info "feed: #{entry}"

          #if !Shortener.instance.public_url_exists?(entry['public_url'])
            MQTT::Client.connect(mqtt_dsn) do |c|
              c.publish('VIDEO', entry.to_json)
            end
          #else
        #    logger.info "got ping for url #{entry['public_url']} but a shortener already exists."
      #    end
        else
          logger.info "no items in feed."
        end
        status 201
      rescue StandardError => e
        logger.error e
        status 500
      end
    elsif params['hub.topic'] &&
      SubscriptionManager.instance.accepted_topics.include?(params['hub.topic'])
      logger.info "verification for valid topic #{params['hub.topic']}"
      params['hub.challenge']
    else
      logger.error "permission denied"
      status 403
    end
  end

  get '/:id' do
    if (link = Shortener.instance.lookup(params[:id]))
      redirect link['stream_url']
    else
      status 404
      body "404"
    end
  end

  get '/' do
    'UP'
  end
end
