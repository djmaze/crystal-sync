class Db::Driver::None < Db::Driver
  def tables; [Db::Table.new(Db.new("dummy") {}, "")]; end
  def clear!; end
  def dump_schema : IO::Memory; IO::Memory.new(0); end
  def load_schema(io : IO); end
  def defer_fk_constraints(&block); end
  def get_array_fields(table : Db::Table); {} of String => Symbol; end
  def offset_sql(offset : Int, limit : Int) : String; ""; end
  def placeholder_type; PlaceholderType::Questionmark; end
  def escape_table_name(name : String) : String; ""; end
  def primary_key_for_table(name : String) : String; ""; end
end
