class Db::Driver::None < Db::Driver
  def schema; nil; end
  def default_schema; nil; end
  def transaction; yield; end
  def tables; [Db::Table.new(Db.new("dummy") {}, "")]; end
  def clear!; end
  def dump_schema : IO::Memory; IO::Memory.new(0); end
  def load_schema(io : IO); end
  def supports_sequences?; false; end
  def dump_sequences : IO::Memory; IO::Memory.new(0); end
  def defer_fk_constraints(&block); end
  def get_array_fields(table : Db::Table); {} of String => Symbol; end
  def offset_sql(offset : Int, limit : Int) : String; ""; end
  def placeholder_type; PlaceholderType::Questionmark; end
  def escape_table_name(name : String) : String; ""; end
  def table_as_csv(table_name : String, &block); end
  def table_from_csv(table_name : String) : {IO, Process}; return IO::Memory.new, Process.new("echo"); end
end
