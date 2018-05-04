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
    @db.exec "DROP DATABASE #{@db.name}"
    @db.exec "CREATE DATABASE #{@db.name}"
  end

  def dump_schema : IO::Memory
    buffer = IO::Memory.new(10*1024)
    Process.run("/bin/sh",
                ["-c",
                 "mysqldump --host=#{@db.uri.host} --user=#{@db.uri.user} --password=#{@db.uri.password} --port=#{@db.uri.port} --no-data #{@db.name}"
                ],
                error: STDERR, output: buffer)
    buffer.rewind
    buffer
  end

  def load_schema(schema_buffer : IO)
    Process.run("/bin/sh",
                ["-c",
                 "mysql --host=#{@db.uri.host} --user=#{@db.uri.user} --password=#{@db.uri.password} #{@db.name}"
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
end
