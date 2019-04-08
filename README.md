# Crystal-Sync

Crystal-Sync is a tool for efficiently transmitting database dumps, optionally including anonymization for table data.

It follows the UNIX philosophy and is split into **dump** and **load** commands. These can be used independently from one another.

The anonymization config needs to be supplied using a DSL written in the [Crystal](http://crystal-lang.org/) language.

Under the hood, the tool dumps and loads the database schema and data using the official client tools for each database. The data is efficiently transmitted using a custom [MessagePack](https://msgpack.org/) format.

Currently, PostgreSQL and MySQL databases are supported.

## Installation

On the system generating the configuration, you need to have [Crystal](http://crystal-lang.org/) 0.27.2 installed.

* Clone this repository
* Compile the CLI:

  ```bash
  cd cli
  shards build
  ```
* The resulting binary can now be found at `bin/crystal-sync_cli` inside the `cli` subdirectory.

## Usage

The CLI is just a generator for a Crystal project with an empty anonymization config.

Complete example:

```bash
# Generate a new configuration
cd cli
bin/crystal-sync_cli generate /path/to/a/new/folder

# Compile the new configuration
cd /path/to/a/new/folder
shards build

# Run the resulting binary
bin/crystal-sync dump [...]
bin/crystal-sync load [...]
```

See the [CLI README](cli/README.md) and the [README for the generated configuration](cli/templates/README.md) for further instructions.

## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/[your-github-name]/crystal-sync/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[djmaze]](https://github.com/djmaze) Martin Honermeyer - creator, maintainer
