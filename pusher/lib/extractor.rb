# frozen_string_literal: true

require 'time'
require 'fileutils'
require 'shellwords'
require 'uri'

require 'mixlib/shellout'
require 'zaru'

#:nodoc:
class Extractor
  attr_accessor :logger
  attr_accessor :message

  def initialize(
      logger:,
      message:,
      download_directory:
  )
    @logger = logger
    @message = message
  end

  # google removes HLS/M3U some time after the stream ended but we should
  # receive the WebSub push fast enough to start scraping.
  #
  def url
    logger.debug "got message: #{message}"
    url = URI.parse(message['url'])
    streamlink_cmd = Mixlib::ShellOut.new("streamlink --stream-url #{url} best")

    retries = 1

    begin
      logger.debug "Getting stream-url, attempt #{retries}:"
      streamlink_cmd.run_command
      logger.error "STDERR: #{streamlink_cmd.stderr}" if streamlink_cmd.error?
      logger.error "STDOUT: #{streamlink_cmd.stdout}" if streamlink_cmd.error?
      streamlink_cmd.error!
    rescue
      sleep retries*10
      retries += 1
      retry if retries < 10

      return ""
    end

    streamlink_cmd.stdout
  end

  protected

  def stream_reader
    StreamReader.new do |line|
      logger.debug(line)
    end
  end
end
