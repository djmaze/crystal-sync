require "pg"

class Db::Driver::Postgres < Db::Driver
  def initialize(@db : Db)
  end

  def tables
    sql = "SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = 'public' ORDER BY table_name;"
    result = @db.query(sql)
    result.rows.map { |row| Db::Table.new(@db, row[0].value.to_s) }
  end

  def clear!
    @db.exec "DROP SCHEMA public CASCADE;"
    @db.exec "CREATE SCHEMA public;"
  end

  def dump_schema : IO::Memory
    buffer = IO::Memory.new(10*1024)
    Process.run("/bin/sh", ["-c", "pg_dump --schema-only --no-owner --no-privileges #{@db.uri}"], env: {"PATH" => ENV["PATH"]}, error: STDERR, output: buffer)
    buffer.rewind
    buffer
  end

  def load_schema(schema_buffer : IO)
    Process.run("/bin/sh", ["-c", "psql #{@db.uri}"], env: {"PATH" => ENV["PATH"]}, input: schema_buffer, error: STDERR)
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
      WHERE table_schema = 'public'
      AND table_name = '#{table.name}' AND data_type = 'ARRAY';"
    )
    result.rows.each do |row|
      name, type = row[0..1]
      case type.value
      when "_varchar", "_text" then array_fields[name.to_s] = :string
      when "_timestamptz" then array_fields[name.to_s] = :time
      when "_float8" then array_fields[name.to_s]  = :float
      else raise "Unsupported array type #{type.value}"
      end
    end
    array_fields
  end
end