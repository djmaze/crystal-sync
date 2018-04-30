class Anonymizer
  def initialize(@config : AnonymizationConfig)
  end

  def skip_table?(table_name : String)
    @config.truncate_table?(table_name)
  end

  def for_table(table : Db::Table)
    table_config = @config.table_config(table.name)
    RowAnonymizer.new(table, table_config)
  end
end
