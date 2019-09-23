struct Db::Value
  @kind = nil
  @string_value : String?
  @time_value : Time?
  @int_value : ((Int8 | Int16 | Int32 | Int64 | UInt32))?
  @bool_value : Bool?
  @float_value : ((Float64 | Float32))?
  @array_value : Array(String)?

  def initialize(string : String | Char)
    @kind = :string
    @string_value = string.to_s
    @int_value = nil
    @bool_value = nil
  end

  def initialize(int : Int8 | Int16 | Int32 | UInt32 | Int64)
    @kind = :int
    @int_value = int
  end

  def initialize(pointer : Slice)
    initialize(String.new(pointer))
    raise "got unexpected pointer: #{String.new(pointer)}"
  end

  def initialize(time : Time)
    @kind = :time
    @time_value = time
  end

  def initialize(bool : Bool)
    @kind = :bool
    @bool_value = bool
  end

  def initialize(float : Float64 | Float32)
    @kind = :float
    @float_value = float
  end

  def initialize(array : Array(String))
    @kind = :array
    @array_value = array
  end

  def initialize(value : Array(PG::BoolArray) | Array(PG::CharArray) | Array(PG::Float32Array) | Array(PG::Float64Array) | Array(PG::Int16Array) | Array(PG::Int32Array) | Array(PG::Int64Array) | Array(PG::NumericArray) | Array(PG::StringArray) | Array(PG::TimeArray) | JSON::Any | PG::Geo::Box | PG::Geo::Circle | PG::Geo::Line | PG::Geo::LineSegment | PG::Geo::Path | PG::Geo::Path | PG::Geo::Point | PG::Geo::Polygon | PG::Numeric | Time::Span)
    raise "DB value type not supported: #{value} #{value.class}"
  end

  def initialize(nothing : Nil)
    @kind = :nil
  end

  def value
    case @kind
    when :string then @string_value
    when :int then @int_value
    when :time then @time_value
    when :bool then @bool_value
    when :float then @float_value
    when :array then @array_value
    when :nil then nil
    else raise "unknown kind #{@kind}"
    end
  end

  def to_i
    @int_value || 0
  end

  def to_s
    value.to_s
  end

  def to_msgpack(packer : MessagePack::Packer)
    case @kind
    when :string then @string_value.to_msgpack(packer)
    when :int then @int_value.to_msgpack(packer)
    # Note: We are loosing time zone information (because of poor MySQL support)
    when :time then @time_value.as(Time).to_msgpack(Time::Format.new("%F %X"), packer)
    when :bool then @bool_value.to_msgpack(packer)
    when :float then @float_value.to_msgpack(packer)
    when :array then @array_value.to_msgpack(packer)
    when :nil then nil.to_msgpack(packer)
    else raise "unknown data type for message pack #{value}"
    end
  end

  def inspect
    "#{value} : #{value.class}"
  end
end
