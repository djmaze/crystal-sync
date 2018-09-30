# Crystal-Sync CLI

This program generates a [Crystal](http://crystal-lang.org/) project with an empty anonymization configuration for [Crystal-Sync](https://github.com/djmaze/crystal-sync).

## Installation

```
shards build
```

The resulting binary can be found at `bin/crystal-sync_cli`


## Usage

```bash
crystal-sync-cli generate <directory>
```

This creates a new directory at `<directory>` with an empty configuration. See the [README for the generated configuration](templates/README.md) for further instructions.
