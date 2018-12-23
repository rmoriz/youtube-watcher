# frozen_string_literal: true

require 'uri'
require 'net/http'

#:nodoc:
class Pusher
  def self.deliver(message_text, message_url = nil)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |h|
      h.request post_request(message_text, message_url)
    end
  end

  def self.uri
    @uri ||= URI.parse('https://api.pushover.net/1/messages.json')
    @uri
  end

  def self.post_request(message_text, message_url)
    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data(
      user: ENV['PUSHOVER_USER_KEY'],
      token: ENV['PUSHOVER_APP_TOKEN'],
      message: message_text,
      url: message_url
    )
    req
  end
end
