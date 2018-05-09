class TableSerializer
  def initialize(@table : Db::Table, @anonymizer : RowAnonymizer)
  end

  def to_msgpack(packer : MessagePack::Packer)
    @table.rows_in_batches do |columns, rows|
      @table.name.to_msgpack(packer)
      columns.to_msgpack(packer)
      anonymized_rows = @anonymizer.anonymize_rows(columns, rows)
      anonymized_rows.to_msgpack(packer)
    end
  end
end
