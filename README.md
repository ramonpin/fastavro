# Fastavro

This library implements some fast avro access functions to be used in conjuction
with avro_ex or schema_avro libraries.

It just contains some convenience functions useful when having high amount of
avro records to process. It allows faster access than the pure elixir libraries
for use cases like:

You need only to read one or a small amount of fields from the avro data but no
modify it. As an example you just need to retrieve some time field to use it as
partitioning value in your destination system.

You want to simplify the message by extracting some fields and reencode with a
diferent schema.

To obtain that speed gain, FastAvro uses a rust wrapper arround the apache-avro
for rust library. It only supports 'record' type at first level of the schema
and only primitive types 'string', 'int', 'long' and 'double' as field types.

```json
{
  "type": "record",
  "name": "person",
  "fields" : [
    {"name": "name", "type": "string"},
    {"name": "age", "type": "int"},
    {"name": "score", "type": "double"}
  ]
}
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `fastavro` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fastavro, "~> 0.3.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/fastavro>.

