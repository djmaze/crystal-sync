require "./crystal-sync/*"
require "../config/anonymization_config"

require "admiral"

class CrystalSync < Admiral::Command
  define_help

  def run
    puts help
  end

  module DbHelpers
    def db_uri?(string : String)
      ["mysql", "postgres"].includes? URI.parse(string).scheme
    end
  end

  class DumpCommand < Admiral::Command
    include DbHelpers

    define_argument database_url : String, required: true, description: "source database URL"
    define_help short: h, description: "Dumps a database while optionally anonymizing data."

    def run
      unless db_uri?(arguments.database_url)
        STDERR.puts "Fatal: invalid database URI! Use either postgres:// or mysql:// scheme"
        exit 1
      end

      output = STDOUT

      config = AnonymizationConfig.instance
      anonymizer = Anonymizer.new(config)
      packer = MessagePack::Packer.new(output)

      Db.new arguments.database_url do |db|
        STDERR.puts "Dumping schema"
        packer.write db.dump_schema.gets_to_end

        db.tables.each do |table|
          if anonymizer.skip_table?(table.name)
            STDERR.puts "Skipping #{table.name}"
          else
            records = table.count
            STDERR.puts "\n#{table.name}: #{records} records"

            if records > 0
              table_anonymizer = anonymizer.for_table(table)
              TableSerializer.new(table, anonymizer: table_anonymizer).to_msgpack(packer)
            end
          end
        end
      end
      packer.write(:EOF)

      STDERR.puts "\nDump finished!"
    end
  end

  class LoadCommand < Admiral::Command
    include DbHelpers

    define_argument database_url : String, required: true, description: "target database URL"
    define_help short: h, description: "Loads a database dump from a crystal-sync dump."

    def run
      unless db_uri?(arguments.database_url)
        STDERR.puts "Fatal: invalid database URI! Use either postgres:// or mysql:// scheme"
        exit 1
      end

      input = STDIN

      Db.new arguments.database_url do |db|
        STDERR.puts "Recreating empty target database"
        db.clear!
      end

      Db.new arguments.database_url do |db|
        STDERR.puts "Loading schema"
        packer = MessagePack::Unpacker.new(input)
        buffer = IO::Memory.new 1024
        buffer.write packer.read_string.to_slice
        buffer.rewind
        db.load_schema(buffer)

        STDERR.puts "Loading data"

        puts "Deferring foreign-key constraints"
        db.defer_fk_constraints do
          last_table_name = ""
          current_loader : (DataLoader | Nil) = nil
          DeserializedData.from_msgpack(input) do |deserialized|
            table_name = deserialized.table_name
            if table_name != last_table_name
              STDERR.printf "\nLoading table #{deserialized.table_name}"
              STDERR.flush
              last_table_name = table_name
              current_loader.done if current_loader
              current_loader = DataLoader.new(db, table_name, deserialized.columns)
            end

            STDERR.printf(".")
            STDERR.flush
            current_loader.not_nil!.load(deserialized)
          end
          current_loader.try &.done
        end
      end

      STDERR.puts "\nLoad finished!"
    end
  end

  register_sub_command :dump, DumpCommand
  register_sub_command :load, LoadCommand
end

CrystalSync.run
