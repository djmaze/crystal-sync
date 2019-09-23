require "csv"

class Db::Table
  LIMIT = 10000

  getter name : String
  getter array_fields = {} of String => Symbol

  def initialize(@db : Db, @name : String)
    @array_fields = @db.get_array_fields(self)
  end

  def count
    result = @db.query "SELECT COUNT(*) FROM #{escaped_name}"
    begin
      result.rows.first[0].to_i
    ensure
      result.close
    end
  end

  def rows_in_batches(&block)
    @db.table_as_csv(@name) do |csv|
      done = false
      0.step(by: LIMIT) do |offset|
        rows = Array(Array(String | Nil)).new(LIMIT)
        LIMIT.times do
          if csv.next && (values = csv.row.to_a).any?
            rows << values.not_nil!.map do |value|
              value.empty? ? nil : value.to_s
            end
          else
            done = true
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
