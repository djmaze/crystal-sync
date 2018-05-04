require "db"

class Db; end

require "./db/*"

class Db
  @db : DB::Database
  @driver : Db::Driver

  def initialize(url)
    @db = DB.open url

    @driver = Db::Driver::None.new
    @driver = case @db.driver
      when PG::Driver then Db::Driver::Postgres.new(self)
      when MySql::Driver then Db::Driver::MySql.new(self)
      else raise "Unsupported driver #{@db.driver}"
    end

    begin
      yield self
    ensure
      @db.close
    end
  end

  def name
    @db.uri.path.as(String)[1..-1]
  end

  def query(sql, *args) : Db::Result
    @db.query(sql, *args) do |rs|
      return Db::Result.new(rs, nil)
    end
  end

  def query(sql, table : Db::Table, *args) : Db::Result
    @db.query(sql, *args) do |rs|
      return Db::Result.new(rs, table)
    end
  end

  def exec(sql, *args)
    @db.exec(sql, *args)
  end

  delegate :tables, :clear!, :dump_schema, :escape_table_name, :get_array_fields, :load_schema, :defer_fk_constraints, :offset_sql, :placeholder_type, :primary_key_for_table, to: @driver
  delegate :transaction, :uri, to: @db
end
