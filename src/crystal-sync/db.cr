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
      else raise "unsupported driver"
    end

    begin
      yield self
    ensure
      @db.close
    end
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

  delegate :tables, :clear!, :dump_schema, :get_array_fields, :load_schema, :defer_fk_constraints, to: @driver
  delegate :transaction, :uri, to: @db
end
