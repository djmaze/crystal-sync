# Crystal-Sync configuration & binary

This directory contains a anonymization configuration for [crystal-sync](https://github.com/djmaze/crystal-sync). The configuration is compiled into a custom binary which can be used for dumping and loading databases using the provided configuration.

## Prerequisites

On the machine generating the binary:

* [Crystal](https://crystal-lang.org/) (currently: 0.30.1) needs to be installed

On the machine running the resulting `crystal-sync` binary:

* You need to have the matching client tools installed:
  * For postgres, `psql` and `pg_dump` are needed
  * For mysql, `mysql` and `mysqldump` are needed

## Configuration

The configuration is contained in the file [anonymization_config.cr](anonymization_config.cr).

It is using a DSL written in the [Crystal language](http://crystal-lang.org/). See the comments in the file for possible options.

As Crystal is a statically compiled language, the resulting binary has to be recompiled after every change to the configuration.

This is done using `shards build`.

You can find the resulting binary in `bin/crystal-sync` afterwards.

## Usage

The resulting binary can be used as follows.

### Dumping a database

```bash
crystal-sync dump <DATABASE_URL>
```

This will dump the database schema and the anonymized data at the standard output.

It is using a custom [MessagePack](https://msgpack.org/) format which can be directly read by `crystal-sync load`.

### Loading a dump into a database

```bash
crystal-sync load <DATABASE_URL>
```

This will drop the current database schema and load the schema and data from the dump given at the standard input.

### Supported database URLs

```
postgres://user:password@host:port/database
mysql://user:passwod@host:port/database
```

For PostgreSQL, it is also possible to specify a source and target schema with the `schema` query parameter:

```
postgres://user:password@host:port/database?schema=foo
```


## Examples

### Dumping to a file

```bash
crystal-sync dump postgres://foo:bar@db/sourcedb >db_dump.bin
```

### Loading from a file

```bash
crystal-sync load postgres://baz:qux@db2/targetdb <db_dump.bin
```

### Dumping and loading via pipe

The dump output can be piped directly into the load input.

```bash
crystal-sync dump postgres://foo:bar@db/sourcedb | crystal-sync load postgres://baz:qux@db2/targetdb
```

There is also an efficient way to transport remote dumps via SSH. In the following example, the `crystal-sync` binary is already installed on the remote server:

```bash
ssh -C user@server crystal-sync dump postgres://foo:bar@db/sourcedb | crystal-sync load postgres://baz:qux@db2/targetdb
```

Alternatively, you can use port forwarding in order to transmit to/from remote servers:

```bash
# in one terminal
ssh -C -L 15432:localhost:5432 user@server
# in a second terminal
crystal-sync dump postgres://foo:bar@localhost:15432/sourcedb | crystal-sync load postgres://baz:qux@db2/targetdb
```
