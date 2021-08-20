require "msgpack"

require "./value"

class Db::Result
  getter rs : DB::ResultSet
  getter columns = [] of String
  getter table : Db::Table?

  class Row
    @row = [] of Db::Value

    def initialize(@result : Db::Result)
      read_row
    end

    delegate :[], :to_a, to: @row

    private def read_row
      @row = @result.columns.map do |name|
        if @result.table
          array_type = @result.table.not_nil!.array_fields[name]?
          val = if array_type
            case array_type
            when :string then @result.rs.read(Array(String))
            when :time then @result.rs.read(Array(String))  # FIXME This might be wrong
            when :float then @result.rs.read(Array(Float64))
            when :int then @result.rs.read(Array(Int64))
            else "unsupported array type #{array_type}"
            end
          else
            @result.rs.read
          end
          Db::Value.new(val)
        else
          Db::Value.new(@result.rs.read)
        end
      end.to_a
    end
  end

  class Rows
    include Enumerable(Row)

    @current_row : Row?

    def initialize(@result : Db::Result)
    end

    def each(&block)
      while self.next
        yield current
      end
    end

    def next
      clear_row
      @result.rs.move_next
    end

    def current : Row
      @current_row ||= get_current
    end

    def clear_row
      @current_row = nil
    end

    private def get_current
      Row.new(@result)
    end
  end

  def initialize(@rs : ::DB::ResultSet, @table : Db::Table?)
    if @rs.column_count > 0
      @columns = @rs.column_count.times.map { |i| @rs.column_name(i) }.to_a
    end
  end

  def close
    @rs.close
  end

  def next
    rows.next
  end

  def headers
    @columns
  end

  def rows
    @rows ||= Rows.new(self)
  end

  def row
    rows.current
  end
end
