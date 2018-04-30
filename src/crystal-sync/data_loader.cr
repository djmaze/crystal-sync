class DataLoader
  def initialize(@db : Db)
  end

  def load(deserialized : DeserializedData)
    sql = "INSERT INTO #{deserialized.table_name.inspect} "
    #sql += "(" + deserialized.columns.join(", ") + ") VALUES "
    sql += "VALUES "
    args = [] of Db::Value

    i = 0
    sql += deserialized.rows.map do |row|
      fields = row.as(Array(MessagePack::Type))

      args += fields
      "(" + fields.size.times.map { "$#{i+=1}" }.join(",") + ")"
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
end
