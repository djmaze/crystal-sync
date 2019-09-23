class RowAnonymizer
  def initialize(@table : Db::Table, @config : AnonymizationConfig::TableConfig)
  end

  def anonymize_rows(columns, rows) : Array(Array(String | Nil))
    rows.map do |row|
      anonymize_row(columns, row)
    end
  end

  def anonymize_row(columns, row) : Array(String | Nil)
    if @config.default?
      row
    else
      columns.map_with_index do |column, i|
        if (val = @config.replace_value[column]?)
          val
        elsif (proc = @config.replace_proc[column]?)
          proc.call row[i]
        else
          row[i]
        end
      end
    end
  end
end
