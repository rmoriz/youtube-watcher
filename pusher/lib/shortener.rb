# frozen_string_literal: true

#:nodoc:
class Shortener
  def self.mqtt_dsn
    'mqtts://' +
      ENV['MQTT_USER'] + ':' +
      ENV['MQTT_PASSWORD'] + '@' +
      ENV['MQTT_SERVER']
  end

  def self.shorten_with_prefix(payload)
    payload['stream_url'] = "vlc://#{payload['stream_url']}"
    shorten payload
  end

  def self.shorten(payload)
    MQTT::Client.connect(mqtt_dsn) do |c|
      c.publish('SHORTENER_REQUEST', payload.to_json)
    end
  end
end
