# frozen_string_literal: true

#:nodoc:
class Shortener
  def self.mqtt_dsn
    'mqtts://' +
      ENV['MQTT_USER'] + ':' +
      ENV['MQTT_PASSWORD'] + '@' +
      ENV['MQTT_SERVER']
  end

  def self.shorten_with_prefix(payload, public_url)
    shorten "vlc://#{payload}", public_url
  end

  def self.shorten(payload, public_url)
    MQTT::Client.connect(mqtt_dsn) do |c|
      c.publish('SHORTENER_REQUEST', {
        url: payload.to_s,
        public_url: public_url.to_s
      }.to_json)
    end
  end

  def self.get_link_for_key(_uri, body)
    JSON.parse(body)['short']
  end
end
