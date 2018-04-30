require "msgpack"

class Db::Result
  getter columns = [] of String
  getter rows = [] of Array(Db::Value)

  def initialize(rs : ::DB::ResultSet, table : Db::Table?)
    if rs.column_count > 0
      # The first row: column names
      @columns = rs.column_count.times.map { |i| rs.column_name(i) }.to_a

      # The result rows
      rs.each do
        @rows << rs.column_count.times.map do |i|
          name = rs.column_name(i)
          if table
            array_type = table.as(Db::Table).array_fields[name]?
            val = if array_type
              case array_type
              when :string then rs.read(Array(String))
              when :time then rs.read(Array(String))  # FIXME This might be wrong
              else "unsupported array type #{array_type}"
              end
            else
              rs.read
            end
            Db::Value.new(val)
          else
            Db::Value.new(rs.read)
          end
        end.to_a
      end
    end
  end
end
