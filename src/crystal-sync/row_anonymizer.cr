class RowAnonymizer
  def initialize(@table : Db::Table, @config : AnonymizationConfig::TableConfig)
  end

  def anonymize_rows(columns, rows)
    if @config.default?
      rows
    else
      rows.map do |row|
        columns.map_with_index do |column, i|
          if (val = @config.replace_value[column]?)
            val
          elsif (proc = @config.replace_proc[column]?)
            if row[i]
              proc.call row[i]
            # FIXME else with nil value
            end
          else
            row[i]
          end
        end
      end
    end
  end
end
