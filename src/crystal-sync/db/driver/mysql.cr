require "mysql"

class Db::Driver::MySql < Db::Driver
  def initialize(@db : Db)
  end

  def schema; nil; end
  def default_schema; nil; end

  def transaction
    # MySQL seems not to support sharing transaction between multiple clients
    yield
  end

  def tables
    sql = "SHOW FULL TABLES WHERE TABLE_TYPE != 'VIEW'"
    result = @db.query(sql)
    begin
      result.rows.map { |row| Db::Table.new(@db, row[0].value.to_s) }
    ensure
      result.close
    end
  end

  def clear!
    @db.exec "DROP DATABASE IF EXISTS #{@db.name}"
    @db.exec "CREATE DATABASE #{@db.name}"
  end

  def dump_schema : IO::Memory
    buffer = IO::Memory.new(10*1024)
    status = Process.run("/bin/sh",
                ["-c",
                 "mysqldump #{mysql_conn_opts} --no-data #{@db.name}"
                ],
                env: {"MYSQL_PWD" => @db.uri.password},
                error: STDERR, output: buffer)
    if status.success?
      buffer.rewind
      buffer
    else
      raise "Fatal: mysqldump exited with code #{status.exit_code}"
    end
  end

  def load_schema(schema_buffer : IO)
    status = Process.run("/bin/sh",
                ["-c",
                 "mysql #{mysql_conn_opts} #{@db.name}"
                ],
                env: {"MYSQL_PWD" => @db.uri.password},
                input: schema_buffer, error: STDERR)
    unless status.success?
      raise "Fatal: mysql exited with code #{status.exit_code}"
    end
  end

  def supports_sequences?
    false
  end

  def dump_sequences : IO::Memory
    IO::Memory.new(0)
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

  def table_as_csv(table_name : String, &block)
    IO.pipe do |read, write|
      sql_command = "SELECT * FROM #{table_name}"
      @db.in_serializable_transaction do
        result = @db.query(sql_command)
        begin
          yield result
        ensure
          result.close
        end
      end
    end
  end

  def table_from_csv(table_name : String) : {IO, Process}
    fifo = create_fifo
    sql_command = %Q(LOAD DATA LOCAL INFILE '#{fifo.path}' INTO TABLE #{table_name} CHARACTER SET 'utf8mb4' FIELDS TERMINATED BY \',\' ENCLOSED BY \'\\"\' LINES TERMINATED BY \'\\n\' IGNORE 1 LINES)
    process = Process.new("/bin/sh",
                ["-c", "mysql --batch #{mysql_conn_opts} #{@db.name} -e \"#{sql_command}\""],
                env: {"MYSQL_PWD" => @db.uri.password},
                error: STDERR, output: STDOUT)

    return File.open(fifo.path, "w"), process
  end

  private def mysql_conn_opts
    "--host=#{@db.uri.host} --user=#{@db.uri.user} --port=#{@db.uri.port || 3306}"
  end

  private def create_fifo : File
    File.tempfile("crystal-sync", "fifo") do |fifo|
      fifo.delete
      `mkfifo -m 0600 #{fifo.path}`
      at_exit { fifo.delete }
    end
  end
end
