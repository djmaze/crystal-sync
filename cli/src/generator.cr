require "file_utils"
require "yaml"

class CrystalSync::Generator
  DEFAULT_PROJECT_NAME = "crystal-sync_config"
  BINARY_NAME = "crystal-sync"

  getter project_dir : String
  getter project_name : String

  def initialize(@project_dir, @project_name=DEFAULT_PROJECT_NAME)
  end

  def run
    if Dir.exists?(project_dir)
      raise "Directory \"#{project_dir}\" already exists"
    end

    create_folder
    write_shards_file
    add_config_file
    add_dockerfile
    add_readme_file
    write_gitignore
    compile_project
  end

  private def create_folder
    FileUtils.mkdir project_dir
  end

  private def write_shards_file
    yaml = YAML.dump({
      name: project_name,
      version: "0.1.0",
      targets: {
        BINARY_NAME => {
          main: File.basename(config_path)
        }
      },
      crystal: Crystal::VERSION,
      dependencies: {
        "crystal-sync": {
          github: "djmaze/crystal-sync",
        }
      }
    })
    File.write(
      File.join(project_dir, "shard.yml"),
      yaml
    )
  end

  private def add_config_file
    FileUtils.cp(
      File.join(template_path, "anonymization_config.cr.example"),
      config_path
    )
  end

  private def add_dockerfile
    FileUtils.cp(
      File.join(template_path, "Dockerfile"),
      File.join(project_dir, "Dockerfile")
    )
  end

  private def add_readme_file
    FileUtils.cp(
      File.join(template_path, "README.md"),
      File.join(project_dir, "README.md")
    )
  end

  private def write_gitignore
    File.write File.join(project_dir, ".gitignore"), <<-TEXT
    /bin
    /lib
    TEXT
  end

  private def compile_project
    within_project do
      Process.run "shards build",
        shell: true,
        error: STDERR,
        output: STDERR
    end
  end

  private def source_dir
    File.join(__DIR__, "../..")
  end

  private def binary_path
    File.join(project_dir, "bin", BINARY_NAME)
  end

  def relative_binary_path
    File.join("bin", BINARY_NAME)
  end

  def config_path
    File.join(project_dir, "anonymization_config.cr")
  end

  def template_path
    File.join(source_dir, "cli", "templates")
  end

  private def within_project
    FileUtils.cd project_dir do
      yield
    end
  end
end
