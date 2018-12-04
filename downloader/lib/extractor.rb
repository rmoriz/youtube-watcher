# frozen_string_literal: true

require 'time'
require 'fileutils'
require 'shellwords'
require 'uri'

require 'mixlib/shellout'

#:nodoc:
class Extractor
  attr_accessor :logger
  attr_accessor :message
  attr_accessor :download_directory

  def initialize(
      logger:,
      message:,
      download_directory:
  )
    @logger = logger
    @message = message

    FileUtils.mkdir_p download_directory
    @download_directory = download_directory
  end

  def url
    logger.debug "got message: #{message}"
    url = URI.parse(message['url'])
    streamlink_cmd = Mixlib::ShellOut.new("streamlink --stream-url #{url} best")
    streamlink_cmd.run_command

    logger.error streamlink_cmd.stderr if streamlink_cmd.error?

    streamlink_cmd.stdout
  end

  def filename
    time = Time.parse message['published']

    Shellwords.escape(
      time.strftime('%Y-%m-%d_%H:%M:%S') +
      '-' +
      message['title'] +
      '-' +
      message['youtube_video_id'] +
      '.mp4'
    )
  end

  def download
    shellout = Mixlib::ShellOut.new(
      download_command(URI.parse(message['url']), filename),
      cwd: @download_directory,
      timeout: 86_400,
      live_stdout: stream_reader,
      live_stderr: stream_reader
    )
    shellout.run_command

    logger.error(shellout.stderr) if shellout.error?
  end

  def download_command(url, filename)
    cmd = <<~END_OF_COMMAND
      streamlink \
        --hls-live-restart \
        --hls-segment-threads 10 \
        --hds-segment-threads 10 \
        --output #{filename} \
        #{url} \
        best
    END_OF_COMMAND

    logger.debug "CMD: #{cmd}"

    cmd
  end

  def stream_reader
    StreamReader.new do |line|
      logger.debug(line)
    end
  end
end