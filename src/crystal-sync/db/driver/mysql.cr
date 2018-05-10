require "tempfile"

require "mysql"

class Db::Driver::MySql < Db::Driver
  def initialize(@db : Db)
  end

  def tables
    sql = "SHOW FULL TABLES WHERE TABLE_TYPE != 'VIEW'"
    result = @db.query(sql)
    result.rows.map { |row| Db::Table.new(@db, row[0].value.to_s) }
  end

  def clear!
    @db.exec "DROP DATABASE IF EXISTS #{@db.name}"
    @db.exec "CREATE DATABASE #{@db.name}"
  end

  def dump_schema : IO::Memory
    buffer = IO::Memory.new(10*1024)
    Process.run("/bin/sh",
                ["-c",
                 "mysqldump #{mysql_conn_opts} --no-data #{@db.name}"
                ],
                error: STDERR, output: buffer)
    buffer.rewind
    buffer
  end

  def load_schema(schema_buffer : IO)
    Process.run("/bin/sh",
                ["-c",
                 "mysql #{mysql_conn_opts} #{@db.name}"
                ],
                input: schema_buffer, error: STDERR)
  end

  def defer_fk_constraints(&block)
    @db.exec "SET foreign_key_checks = 0"
    yield
    @db.exec "SET foreign_key_checks = 1"
  end

  def get_array_fields(table : Db::Table) : Hash(String, Symbol)
    # TODO
    {} of String => Symbol
  end

  def offset_sql(offset : Int, limit : Int) : String
    "LIMIT #{offset}, #{limit}"
  end

  def placeholder_type
    PlaceholderType::Questionmark
  end

  def escape_table_name(name : String) : String
    "`#{name}`"
  end

  def primary_key_for_table(name : String) : String
    sql = "SHOW KEYS FROM #{name} WHERE Key_name = 'PRIMARY'"
    result = @db.query(sql)
    result.rows.first[0].to_s
  end

  def table_as_csv(table_name : String, &block)
    IO.pipe do |read, write|
      # https://stackoverflow.com/a/25427665/3515146
      sql_command = "SELECT * FROM #{table_name}"
      sed_command = %q(sed "s/'/\'/;s/\t/\",\"/g;s/^/\"/;s/$/\"/;s/\n//g")
      Process.run("/bin/sh", ["-c", "mysql --batch #{mysql_conn_opts} #{@db.name} -e \"#{sql_command}\" | #{sed_command}; echo \"\n\""], error: STDERR, output: write) do
        yield read
      end
    end
  end

  def table_from_csv(table_name : String) : IO
    fifo = create_fifo
    sql_command = %Q(LOAD DATA LOCAL INFILE '#{fifo.path}' INTO TABLE #{table_name} FIELDS TERMINATED BY \',\' ENCLOSED BY \'\\"\' LINES TERMINATED BY \'\\n\' IGNORE 1 LINES)
    Process.new("/bin/sh", ["-c", "mysql --batch #{mysql_conn_opts} #{@db.name} -e \"#{sql_command}\""], error: STDERR, output: STDOUT)
    File.open(fifo.path, "w")
  end

  private def mysql_conn_opts
    "--host=#{@db.uri.host} --user=#{@db.uri.user} --password=#{@db.uri.password} --port=#{@db.uri.port || 3306}"
  end

  private def create_fifo : Tempfile
    Tempfile.open("crystal-sync", "fifo") do |fifo|
      fifo.unlink
      `mkfifo -m 0600 #{fifo.path}`
      at_exit { fifo.unlink }
    end
  end
end
