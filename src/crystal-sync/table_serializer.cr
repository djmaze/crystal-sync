class TableSerializer
  def initialize(@table : Db::Table, @anonymizer : RowAnonymizer)
  end

  def to_msgpack(packer : MessagePack::Packer)
    @table.rows_in_batches do |result|
      @table.name.to_msgpack(packer)
      result.columns.to_msgpack(packer)
      anonymized_rows = @anonymizer.anonymize_rows(result.columns, result.rows)
      anonymized_rows.to_msgpack(packer)
    end
  end
end
