require "csv"

class Db::Table
  LIMIT = 10000

  getter name : String
  getter array_fields = {} of String => Symbol
  getter primary_key : String

  def initialize(@db : Db, @name : String)
    @primary_key = ""
    @array_fields = @db.get_array_fields(self)
    @primary_key = @db.primary_key_for_table(@name)
  end

  def [](offset : Int, limit : Int)
    @db.query("SELECT * FROM #{escaped_name} ORDER BY #{primary_key} #{@db.offset_sql(offset, limit)}", self)
  end

  def count
    result = @db.query "SELECT COUNT(*) FROM #{escaped_name}"
    result.rows.first[0].to_i
  end

  def rows_in_batches(&block)
    @db.table_as_csv(@name) do |buffer|
      csv = CSV.new(buffer, headers: true)
      done = false
      0.step(by: LIMIT) do |offset|
        rows = Array(Array(String)).new(LIMIT)
        LIMIT.times do
          break if buffer.closed? || !csv.next
          if csv.row.to_a.empty?
            done = true
          else
            rows << csv.row.to_a
          end
          break if done
        end
        yield csv.headers, rows if rows.any?
        break if done
      end
    end
  end

  def inspect
    @name
  end

  def escaped_name
    @db.escape_table_name(@name)
  end
end
