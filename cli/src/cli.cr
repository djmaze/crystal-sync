require "admiral"

require "./generator"

class CrystalSync::Cli < Admiral::Command
  define_help

  def run
    puts help
  end

  class GenerateCommand < Admiral::Command
    define_argument directory : String, required: true, description: "where to generate the config"
    define_help short: h, description: "Generates a new anonymization config in a folder"

    def run
      generator = Generator.new arguments.directory
      begin
        generator.run
      rescue e
        return fatal e.message || e.inspect
      end

      text = <<-TEXT

      #{"Success!".colorize(:green).bold} Generated config in #{generator.project_dir.colorize.bold}

      #{"Next steps:".colorize.bold}
      - change directory to #{generator.project_dir.colorize.bold}
      - edit the config in #{File.basename(generator.config_path).colorize.bold}
      - recompile using #{"shards build".colorize.bold}
      - run #{generator.relative_binary_path.colorize.bold}

      Make sure to have a look at the README as well.
      TEXT
      puts text
    end

    def fatal(message)
      STDERR.puts "#{"Fatal".colorize(:red)}: #{message}"
      exit 1
    end
  end

  register_sub_command :generate, GenerateCommand
end

CrystalSync::Cli.run
