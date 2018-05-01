class DataLoader
  def initialize(@db : Db)
    @i = 0
  end

  def load(deserialized : DeserializedData)
    sql = "INSERT INTO #{deserialized.table_name} "
    #sql += "(" + deserialized.columns.join(", ") + ") VALUES "
    sql += "VALUES "
    args = [] of Db::Value

    reset_placeholder
    sql += deserialized.rows.map do |row|
      fields = row.as(Array(MessagePack::Type))

      args += map_fields(fields)
      "(" + fields.size.times.map { placeholder }.join(",") + ")"
    end.join(",")

    sql += ";"

    begin
      @db.exec(sql, args)
    rescue ex
      STDERR.puts "Error during import of #{deserialized.table_name}!"
      STDERR.puts ex.message.as(String)[0,500]
      raise "import failed"
    end
  end

  private def placeholder
    case @db.placeholder_type
    when Db::Driver::PlaceholderType::IncrementedDollar
      "$#{@i+=1}"
    when Db::Driver::PlaceholderType::Questionmark
      "?"
    end
  end

  private def reset_placeholder
    @i = 0
  end

  private def map_fields(fields : Array(MessagePack::Type))
    fields.map do |field|
      case field
      # MySQL (driver?) does not support UInt* fields
      when UInt8, UInt16 then field.to_i
      when UInt32 then field.to_i
      else
        field
      end
    end
  end
end
