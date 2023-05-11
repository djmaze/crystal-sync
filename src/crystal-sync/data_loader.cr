class DataLoader
  @table_buffer : IO
  @process: Process

  def initialize(@db : Db, @table_name : String, columns : Array(String))
    @i = 0
    @table_buffer, @process = @db.table_from_csv(table_name)
    @csv = CSV::Builder.new(@table_buffer)
    @csv.row columns
  end

  def load(deserialized : DeserializedData)
    deserialized.rows.each do |row|
      @csv.row row
    end
  end

  def done
    @table_buffer.close
    @process.wait
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
