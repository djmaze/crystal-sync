require "./crystal-sync/*"
require "../config/anonymization_config"

require "admiral"

class CrystalSync < Admiral::Command
  define_argument database_source : String, required: true, description: "source database URL or filename"
  define_argument database_target : String, required: true, description: "target database URL or filename"
  define_help short: h, description: "Copies a source into a target database, while optionally anonymizing data.

The source and target arguments have to be database URLs in the form of:

    postgres://<user>:<password>@<host>:<port>/<database>
    mysql://<user>:<password>@<host>:<port>/<database>"

  def run
    unless db_uri?(arguments.database_source) && db_uri?(arguments.database_target)
      STDERR.puts "Fatal: invalid database URI! Use either postgres:// or mysql:// scheme for both arguments"
      exit 1
    end

    schema = IO::Memory.new 0       # FIXME Find better way to prevent compilation error

    config = AnonymizationConfig.instance
    anonymizer = Anonymizer.new(config)
    packer = MessagePack::Packer.new

    dump_channel = Channel(Nil).new
    Db.new arguments.database_source do |db|
      spawn do
        STDERR.puts "Dumping schema in the background"
        schema = db.dump_schema
        dump_channel.send nil
      end

      db.tables.each do |table|
        if anonymizer.skip_table?(table.name)
          STDERR.puts "Skipping #{table.name}"
        else
          records = table.count
          STDERR.puts "#{table.name}: #{records} records"

          if records > 0
            table_anonymizer = anonymizer.for_table(table)
            TableSerializer.new(table, anonymizer: table_anonymizer).to_msgpack(packer)
          end
        end
      end
    end
    packer.write(:EOF)
    packed = packer.to_slice

    STDERR.printf "Waiting for dump to finish.."
    STDERR.flush
    dump_channel.receive
    STDERR.puts "\nExport finished!"

    Db.new arguments.database_target do |db|
      STDERR.puts "Recreating empty target database"
      db.clear!
    end

    Db.new arguments.database_target do |db|
      STDERR.puts "Loading schema"
      db.load_schema(schema)

      STDERR.puts "Loading data"

      loader = DataLoader.new(db)

      puts "Deferring foreign-key constraints"
      db.defer_fk_constraints do
        last_table_name = ""
        DeserializedData.from_msgpack(packed) do |deserialized|
          table_name = deserialized.table_name
          if table_name != last_table_name
            STDERR.printf "\nLoading table #{deserialized.table_name}"
            STDERR.flush
            last_table_name = table_name
          end

          STDERR.printf(".")
          STDERR.flush
          loader.load(deserialized)
        end
      end
    end

    STDERR.puts "\nImport finished!"
  end

  def db_uri?(string : String)
    ["mysql", "postgres"].includes? URI.parse(string).scheme
  end
end

CrystalSync.run
