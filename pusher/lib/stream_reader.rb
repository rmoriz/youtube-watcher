# frozen_string_literal: true

require 'stringio'

#:nodoc:
class StreamReader
  def initialize(&block)
    @block = block
    @buffer = StringIO.new
    @buffer.sync = true if @buffer.respond_to?(:sync)
  end

  def <<(chunk)
    @buffer.write(chunk)
    @buffer.rewind

    overflow = process_each_line

    @buffer.truncate(@buffer.rewind)
    @buffer.write(overflow)
  end

  def process_each_line
    overflow = ''

    @buffer.each_line do |line|
      if /\r?\n/.match?(line)
        @block.call(line.strip)
      else
        overflow = line
      end
    end

    overflow
  end
end
