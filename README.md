# Tideland Elixir Application Support

## Description

The *Tideland Elixir Application Support* (EXAS) is a collection of smaller 
helpful modules for multiple purposes. They are those little helpers we
always need. See their descriptions below.

**Have fun. ;)**

## Installation

## Usage

### Identifier

Identifiers are needed in most applications. `EXAS.Identifier` provides two diffent
ones:

- natural identifiers built out of passed information,
- UUIDs.

The natural ones are created by calling

```
id = EXAS.Identifier.new([:part, "of", :id, 1])
```

This returns *"part-of-id-1"*. An optional second argument can be used to set a
different joiner instead of the dash, e.g. a slash. And another optional third 
argument can be used to pass a mapper function, e.g. to convert upper-case strings
into lower-case strings.

UUIDs can be generated in the versions v1, v3, v4, and v5:

```
EXAS.Identifier.new_uuid_v1(format)
EXAS.Identifier.new_uuid_v3(type, name, format)
EXAS.Identifier.new_uuid_v4(format)
EXAS.Identifier.new_uuid_v5(type, name, format)
```

`format` has the default value `:default` so that the UUID is returned in its
standard string representation with dashes. Other allowed formats are

- `:binary` to return it as 128 bit binary,
- `:hex` to return it as hex string without dashes, and
- `:urn` to return it like default but prefixed with "urn:uuid:".

The types for v3 and v5 are

- `:dns` to define DNS as namespace for name,
- `:url` to define URL,
- `:oid` to define object ID,
- `:x500` to define X.500, 
- `nil` to set no namespace, and
- another UUID as individual namespace.

Any UUID can be analyzed with `EXAS.Identifier.parse_uuid(uuid)`, which returns
a tuple `{:ok, uuid_bin, version, variant}`. 

### Top

The module `EXAS.Top` allows to measure the execution time of a piece of code during
runtime in a simple way. One way is to surround the block to measure:

```
measuring = EXAS.Top.begin_measuring("my-measuring-point")
do_something_interesting()
EXAS.Top.end_measuring(measuring)
```

A simpler way is to measure an expression using the macro

```
EXAS.Top.measure "my-measuring-point" do
    ...
end
```

The measurings can be retrieved with `EXAS.Top.retrieve`, which returns a
list of records. These contain the measuring point, the number of calls, the
minimum and the maximum measured times, the average time, and the total time.
The measurings can be reset with `EXAS.Top.reset`.

### Stay-Set Variables

The module `EXAS.SSV` allows to monitor numerical values over time. They are
set by calling

```
EXAS.SSV.set(:my_variable, 1)
EXAS.SSV.set(:my_variable, 17)
EXAS.SSV.set(:my_variable, -1)
```

Additionally simple changes by calling

```
EXAS.SSV.increase(:my_variable)
EXAS.SSV.decrease(:my_variable)
```

The Variables can be retrieved by calling `EXAS.SSV.retrieve`. For each variable
the actual, minimum, and maximum values are returned together with their timestamps.
Additionally the total number of settings and the average value.

### Dynamic Status Retrievers

With the module `EXAS.DSR` functions for the retrieval of a status can be registered
with an identifier. Those functions can e.g. communicate to other processes, check
the existence of files, or the reachability of other nodes. When the states are
retrieved by calling `EXAS.DSR.retrieve` the functions will be executed and the result
returned.

## Contributors

- Frank Mueller - <mue@tideland.biz>

## License

*Tideland Elixir Application Support* is distributed under the terms of the BSD 3-Clause license.

