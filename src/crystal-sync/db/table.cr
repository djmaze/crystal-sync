class Db::Table
  LIMIT = 1000

  getter name : String
  getter array_fields = {} of String => Symbol

  def initialize(@db : Db, @name : String)
    @array_fields = @db.get_array_fields(self)
  end

  def [](offset : Int, limit : Int)
    @db.query("SELECT * FROM #{escaped_name} #{@db.offset_sql(offset, limit)}", self)
  end

  def count
    result = @db.query "SELECT COUNT(*) FROM #{escaped_name}"
    result.rows.first[0].to_i
  end

  def rows_in_batches
    0.step(to: count, by: LIMIT) do |offset|
      yield self[offset, LIMIT]
    end
  end

  def inspect
    @name
  end

  def escaped_name
    @db.escape_table_name(@name)
  end
end
