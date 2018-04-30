class Db::Driver::None < Db::Driver
  def tables; [Db::Table.new(Db.new("dummy") {}, "")]; end
  def clear!; end
  def dump_schema : IO::Memory; IO::Memory.new(0); end
  def load_schema(io : IO); end
  def defer_fk_constraints(&block); end
  def get_array_fields(table : Db::Table); {} of String => Symbol; end
end