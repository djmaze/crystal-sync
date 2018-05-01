abstract class Db::Driver
  enum PlaceholderType
    Questionmark
    IncrementedDollar
  end
end

require "./driver/*"
