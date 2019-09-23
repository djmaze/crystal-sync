require "csv/builder"

class NullableCSVBuilder < CSV::Builder
  def initialize(@io : IO, @separator : Char = CSV::DEFAULT_SEPARATOR, @quote_char : Char = CSV::DEFAULT_QUOTE_CHAR, @quoting : Quoting = Quoting::RFC)
    super
    @buffer = IO::Memory.new 16 * 1024
  end

  def cell
    append_cell do
      yield @buffer
      if @buffer.empty?
        @io << "NULL"
      else
        @buffer.rewind
        @io << @buffer
        @buffer.clear
      end
    end
  end
end

