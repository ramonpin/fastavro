defmodule FastAvro do
  @moduledoc """
  This library implements some fast avro access functions to be used in
  conjuction with [avro_ex](https://hexdocs.pm/avro_ex) or
  [schema_avro](https://hexdocs.pm/avro_schema/AvroSchema.html) libraries.

  It just contains some convenience functions useful when having high amount of
  avro records to process. It allows faster access than the pure elixir
  libraries for use cases like:

  - You need only to read one or a small amount of fields from the avro data
  but no modify it. As an example you just need to retrieve some time field to
  use it as partitioning value in your destination system.

  - You want to simplify the message by extracting some fields and reencode
  with a diferent schema.

  To obtain that speed gain, FastAvro uses a rust wrapper arround the
  [apache-avro for rust library](https://crates.io/crates/apache-avro). It only
  supports 'record' type at first level of the schema and only primitive types
  'string', 'int', 'long' and 'double' as field types.

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
  """

  use Rustler, otp_app: :fastavro, crate: "fastavro"

  @typedoc """
  Is a precompiled and validated avro schema
  """
  @type schema :: reference

  @typedoc """
  Is a decoded and schema validated avro record
  """
  @type avro_record :: reference

  @doc """
  This function parses and validates a avro schema given as a json encoded
  string.

  It returns creates an internal representation of the schema ready to
  be used with `FastAvro.create_msg/2` or `FastAvro.decode_avro_datum/2`.

  ## Parameters
  - json: a string containing the schema definition json encoded.

  ## Returns

  - `{:ok, schema}`
  - `{:error, reason}`

  ## Examples

      iex> {:ok, schm} = File.read!("bench/lte_202210.avsc") |> FastAvro.read_schema
      {:ok, #Reference<0.3029127103.749076481.152983>}

  In order to interoperate with the rest of the module the schema must define a
  'record' with only primitive 'string', 'int', 'long' and 'double' fields.
  """
  @spec read_schema(String.t()) :: {:ok, schema} | {:error, atom}
  def read_schema(_json), do: error()

  @doc """
  Given a schema it makes a list of fields and their types.

  ## Parameters

  - schema: a `schema()` reference.

  ## Resturns

  A map with field names and types as string binaries.

  ## Examples

      iex> FastAvro.schema_fields(schema)
      %{
        "S1_Attach_Attempt" => "Int",
        "Report_Reason" => "Int",
        "Dest_Cell_Id" => "String",
        "NRN_llamante" => "String",
        "Dest_SAC" => "String"
      }

  This is useful if you need to instrospect the schema.
  """
  @spec schema_fields(schema) :: list
  def schema_fields(_schema), do: error()

  @doc """
  Creates a new avro record from a map of field names as string
  binaries and values compatible with the given schema.

  All mandatory fields must be provided and the asociated values
  must correctly typed.

  ## Parameters
  - map: an elixir map with fields to be populated
  - schema: a `schema()` reference for the record format

  ## Returns

  - `{:ok, avro_record}`: an `avro_record()` reference already populated and ready
    to be encoded.
  - `{:error, :wrong_type}`: if the schema contains an unknown data type. 

  ## Examples

      iex> {:ok, record} = FastAvro.create_msg(
             %{ "name" => "John", "age" => 25, "score" => 5.6 },
             schema
           )
      {:ok, #Reference<0.2515214245.918683654.17019>}


  """
  @spec create_msg(map, schema) :: {:ok, avro_record} | {:error, atom}
  def create_msg(_map, _schema), do: error()

  @doc """
  Converts an `avro_record()` reference into an elixir map.

  ## Parameters

  - `avro_record`: an `avro_record()` reference to convert.

  ## Retunrs

  An elixir map with avro field names as keys and avro field values as values.

  ## Examples

      iex> FastAvro.to_map(msg)
      %{
        "S1_Attach_Attempt" => 0,
        "Report_Reason" => 19,
        "Dest_Cell_Id" => "",
        "NRN_llamante" => "",
        "Dest_SAC" => "TAC: 1142",
      }

  """
  @spec to_map(avro_record) :: map
  def to_map(_msg), do: error()

  @doc """
  Decodes avro data given as a binary using the provided schema. It decodes
  only raw data without any headers, no schema and no fingerprint.

  ## Parameters

  - `binary`: valid avro data as a binary
  - `schema`: a `schema()` reference for a record definition compatible with the
    data.

  ## Returns

  - `{:ok, avro_record()}`: when successfully decoded
  - `{:error, :incompatible_avro_schema}`: when schema not valid to decode data.

  ## Examples

      iex> FastAvro.decode_avro_datum(avro_data, schema)
      {:ok, #Reference<0.2887345315.2965241864.83696>}
  """
  @spec decode_avro_datum(binary, schema) :: {:ok, avro_record} | {:error, atom}
  def decode_avro_datum(_avro_data, _schema), do: error()

  @doc """
  Encodes avro data from a map using the provided schema. It raw encodes
  the data without any headers, no schema and no fingerprint.

  ## Parameters

  - `map`: elixir map with field names and values to encode
  - `schema`: a `schema()` reference compatible with the fields and values in
    the map.

  ## Returns

  - `{:ok, binary}`: binary contains avro representation of the data in
  the map as described by the schema.
  - `{:error, :wrong_type}`: the schema contains an unsupported data type
  - `{:error, :incompatible_avro_schema}`: the schema does not match map contents
  - `{:error, :field_not_found}`: if map field missing from schema

  If the schema is not compatible with the map contents it raises an exception.

  ## Examples

      iex> FastAvro.encode_avro_datum(
        %{
          "tac" => 1432,
          "from" => "2023-01-25 00:45:52",
          "to" => "2023-01-25 01:00:00"
        },
        new_schema
      )
      {:ok, <<176, 22, 38, 50, 48, 50, 51, 45, 48, 49, 45, 50, 53, 32, 48, 48, 58,
      52, 53, 58, 53, 50, 38, 50, 48, 50, 51, 45, 48, 49, 45, 50, 53, 32, 48,
      49, 58, 48, 48, 58, 48, 48>>}

  """
  @spec encode_avro_datum(map, schema) :: {:ok, binary} | {:error, atom}
  def encode_avro_datum(_avro_map, _schema), do: error()

  @doc """
  Gets the value associated to a field name from a given avro record.

  ## Parameters

  - `avro_record`: a `avro_record()` reference already decoded
  - `name`: the field name to consult as a string

  ## Returns

  - `{:ok, term}`: term representing the value of the field in the avro record
  - `{:error, :field_not_found}`: If the field does not exist in the avro record
  - `{:error, :not_a_record}`: If the binary is not an avro record

  ## Examples

      iex> FastAvro.get_avro_value(msg, "Dest_TAC")
      {:ok, "TAC: 1142"}
  """
  @spec get_avro_value(avro_record, String.t()) :: term
  def get_avro_value(_msg, _name), do: error()

  @doc """
  Gets the value associated to a field name from given avro data and schema.

  ## Parameters

  - `avro_binary`: valid avro data as a binary
  - `schema`: a `schema()` reference compatible with that avro data.
  - `name`: the field name to consult as a string

  ## Returns

  - `{:ok, term}`: term representing the value of the field in the avro record
  - `{:error, :field_not_found}`: If the field does not exist in the avro record
  - `{:error, :not_a_record}`: If the binary is not an avro record
  - `{:error, :incompatible_avro_schema}`: If the schema is not compatible with the binary

  ## Examples

      iex> FastAvro.get_raw_value(avro_binary, "Dest_TAC")
      {:ok, "TAC: 1142"}
  """
  @spec get_raw_value(binary, schema, String.t()) :: term
  def get_raw_value(_avro_binary, _schema, _name), do: error()

  @doc """
  Gets the values associated with a list of field names from given avro data
  and schema.

  ## Parameters

  - `avro_binary`: valid avro data as a binary
  - `schema`: a `schema()` reference compatible with that avro data.
  - `names`: a list of field names to consult as a strings

  ## Returns

  An elixir term representing the value of the field in the avro record.

  If the field does not exists in the avro record you get :field_not_found.

  ## Examples

  ```
  iex> FastAvro.get_raw_values(avro_data, schema, [
    "Dest_TAC",
    "Event_Start",
    "Event_Stop"
  ])
  %{
    "Dest_TAC" => "TAC: 1142",
    "Event_Start" => "20200914 18:03:03.174",
    "Event_Stop" => "20200914 18:03:03.224"
  }
  ```
  """
  @spec get_raw_values(binary, schema, [String.t()]) :: map
  def get_raw_values(_avro_binary, _schm, _names), do: error()

  defp error(), do: :erlang.nif_error(:nif_not_loaded)
end
