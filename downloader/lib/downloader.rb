# frozen_string_literal: true

require 'time'
require 'fileutils'
require 'shellwords'
require 'uri'

require 'mixlib/shellout'
require 'zaru'

#:nodoc:
class Downloader
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

  def capture_stream
    directory = ::File.join(@download_directory, Zaru.sanitize!(message['author']))
    FileUtils.mkdir_p directory

    shellout = Mixlib::ShellOut.new(
      download_command(
        URI.parse(message['url']),
        filename
      ),
      cwd: directory,
      timeout: 86_400,
      live_stdout: stream_reader,
      live_stderr: stream_reader
    )
    shellout.run_command

    logger.error(shellout.stderr) if shellout.error?
  end

  # TODO: Fix broken files, e.g. corrupt streaming
  # ffmpeg -err_detect ignore_err -i video.mp4 -c copy video_fixed.mp4
  #
  # ... but I need to find out error detection first. :(

  def download_command(url, filename)
    cmd = <<~END_OF_COMMAND
      streamlink \
        --hls-live-restart \
        --hls-segment-threads 2 \
        --hds-segment-threads 2 \
        --retry-streams 10 \
        --retry-max 60 \
        --retry-open 10 \
        --default-stream best \
        --output #{filename} \
        #{url} \
        best
    END_OF_COMMAND

    logger.debug "CMD: #{cmd}"
    cmd
  end

  protected

  def filename
    time = Time.parse message['published']

    Shellwords.escape(
      time.strftime('%Y-%m-%d_%H%M%S') +
      '-' +
      Zaru.sanitize!(message['title']) +
      '-' +
      message['youtube_video_id'] +
      '.mp4'
    )
  end

  def stream_reader
    StreamReader.new do |line|
      logger.debug(line)
    end
  end
end
