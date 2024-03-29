require "pg"

class Db::Driver::Postgres < Db::Driver
  getter schema : String
  getter snapshot : String?

  def initialize(@db : Db, schema : String?)
    @schema = schema || default_schema
  end

  def default_schema
    "public"
  end

  def transaction(&block)
    @db.exec("BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ")
    begin
      @snapshot = @db.scalar("SELECT pg_export_snapshot()").as(String)
      yield
    ensure
      @db.exec("ROLLBACK")
    end
  end

  def tables
    sql = "SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = '#{@schema}' ORDER BY table_name;"
    result = @db.query(sql)
    begin
      result.rows.map { |row| Db::Table.new(@db, row[0].value.to_s) }
    ensure
      result.close
    end
  end

  def clear!
    @db.exec "DROP SCHEMA IF EXISTS #{@schema} CASCADE;"
    @db.exec "CREATE SCHEMA #{@schema};"
  end

  def dump_schema : IO::Memory
    buffer = IO::Memory.new(10*1024)
    dump_tables(buffer)
    buffer.rewind
    buffer
  end

  def load_schema(schema_buffer : IO)
    Process.run("/bin/sh", ["-c", "psql #{@db.uri}"], env: {"PATH" => ENV["PATH"]}, input: schema_buffer, error: STDERR)
  end

  def supports_sequences?
    true
  end

  def dump_sequences : IO::Memory
    buffer = IO::Memory.new(10*1024)

    unless sequences.none?
      table_args = sequences.map do |sequence|
        "-t #{sequence}"
      end.join(" ")
      Process.run("/bin/sh", ["-c", "pg_dump --data-only --no-owner --no-privileges --snapshot #{@snapshot} -n #{@schema} #{table_args} #{@db.uri}"], error: STDERR, output: buffer)
    end

    buffer.rewind
    buffer
  end

  def defer_fk_constraints(&block)
    @db.transaction do
      # FIXME Deferring constraints does somehow not work, disabling all triggers instead
      #@db.exec "SET CONSTRAINTS ALL DEFERRED"
      tables.each do |table|
        @db.exec "ALTER TABLE #{table.escaped_name} DISABLE TRIGGER ALL;"
      end
      yield
      tables.each do |table|
        @db.exec "ALTER TABLE #{table.escaped_name} ENABLE TRIGGER ALL;"
      end
    end
  end

  def get_array_fields(table : Db::Table) : Hash(String, Symbol)
    array_fields = {} of String => Symbol
    result = @db.query(
      "SELECT column_name, udt_name
      FROM information_schema.columns
      WHERE table_schema = '#{@schema}'
      AND table_name = '#{table.name}' AND data_type = 'ARRAY';"
    )
    begin
      result.rows.each do |row|
        name, type = row[0..1]
        case type.value
        when "_varchar", "_text" then array_fields[name.to_s] = :string
        when "_timestamptz" then array_fields[name.to_s] = :time
        when "_float8" then array_fields[name.to_s]  = :float
        when "_int4" then array_fields[name.to_s] = :int
        else raise "Unsupported array type #{type.value}"
        end
      end
      array_fields
    ensure
      result.close
    end
  end

  def offset_sql(offset : Int, limit : Int) : String
    "OFFSET #{offset} LIMIT #{limit}"
  end

  def placeholder_type
    PlaceholderType::IncrementedDollar
  end

  def escape_table_name(name : String) : String
    %Q(#{@schema}."#{name}")
  end

  def table_as_csv(table_name : String, &block)
    IO.pipe do |read, write|
      sql = "BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
        SET TRANSACTION SNAPSHOT '#{@snapshot}';
        COPY #{@schema}.#{table_name} TO STDOUT WITH (FORMAT csv, HEADER true, NULL '\\N');"
      Process.run("/bin/sh", ["-c", "psql #{@db.uri} -q -c \"#{sql}\"; echo \"\n\""], error: STDERR, output: write) do
        yield CSV.new(read, headers: true)
      end
    end
  end

  def table_from_csv(table_name : String) : {IO, Process}
    read, write = IO.pipe
    process = Process.new(
      "psql #{@db.uri} -a -c \"COPY #{table_name} FROM STDIN WITH (FORMAT csv, HEADER true, NULL '\\N')\"",
      shell: true,
      input: read,
      error: STDERR
    )
    return write, process
  end

  private def dump_tables(buffer : IO)
    Process.run("/bin/sh", ["-c", "pg_dump --schema-only --no-owner --no-privileges -n #{@schema} #{@db.uri}"], error: STDERR, output: buffer)
  end

  private def sequences
    sql = "SELECT c.relname as sequence_name
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN pg_user u ON u.usesysid = c.relowner
      WHERE c.relkind = 'S' AND n.nspname = '#{@schema}'
      ORDER BY sequence_name;"
    result = @db.query(sql)
    begin
      result.rows.map { |row| row[0].value.to_s }
    ensure
      result.close
    end
  end
end
