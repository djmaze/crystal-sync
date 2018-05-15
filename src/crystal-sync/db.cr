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
    rs = @db.query(sql, *args)
    return Db::Result.new(rs, nil)
  end

  def query(sql, table : Db::Table, *args) : Db::Result
    rs = @db.query(sql, *args)
    return Db::Result.new(rs, table)
  end

  def exec(sql, *args)
    @db.exec(sql, *args)
  end

  def in_serializable_transaction(&block)
    transaction do
      exec "SET TRANSACTION ISOLATION LEVEL SERIALIZABLE, READ ONLY"    # FIXME DEFERRABLE needed for Postgres?
      yield
    end
  end

  delegate :tables, :clear!, :dump_schema, :escape_table_name, :get_array_fields, :load_schema, :defer_fk_constraints, :offset_sql, :placeholder_type, :table_as_csv, :table_from_csv, to: @driver
  delegate :transaction, :uri, to: @db
end
