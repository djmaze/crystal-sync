class AnonymizationConfig
  getter tables = {} of String => TableConfig

  def self.instance
    @@instance ||= new
  end

  def self.define(&block)
    with instance yield
  end

  def table(name, &block)
    with table_config(name) yield
  end

  def truncate_table?(name)
    table_config(name).truncate?
  end

  def table_config(name)
    @tables[name] ||= TableConfig.new(name)
  end

  class TableConfig
    getter? default = true
    getter? truncate = false
    getter replace_value = {} of String => String?
    getter replace_proc = {} of String => Proc(String, String)

    def initialize(@name : String)
    end

    def truncate
      @default = false
      @truncate = true
    end

    def replace(field : Symbol, with_value : String)
      @default = false
      @replace_value[field.to_s] = with_value
    end

    def replace(field : Symbol, &block : String -> String)
      @default = false
      @replace_proc[field.to_s] = block
    end

    def remove(field : Symbol)
      @default = false
      @replace_value[field.to_s] = nil
    end
  end
end
