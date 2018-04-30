class DeserializedData
  getter :table_name, :columns, :rows

  def self.from_msgpack(string_or_io)
    parser = MessagePack::Unpacker.new(string_or_io)

    while (table_name_or_eof = parser.read) != "EOF"
      table_name = table_name_or_eof.as(String)
      columns = parser.read.as(Array(MessagePack::Type))
      rows = parser.read.as(Array(MessagePack::Type))
      yield new(table_name, columns, rows)
    end
  end

  def initialize(@table_name : String, @columns : Array(MessagePack::Type), @rows : Array(MessagePack::Type))
  end
end
