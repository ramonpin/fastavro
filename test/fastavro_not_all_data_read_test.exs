defmodule FastAvroNotAllDataReadTest do
  use ExUnit.Case

  @long_schema """
  {
    "type": "record",
    "name": "test",
    "fields": [
      {"name": "name", "type": "string"},
      {"name": "age", "type": "int"},
      {"name": "score", "type": "double"}
    ]
  }
  """

  @short_schema """
  {
    "type": "record",
    "name": "test",
    "fields": [
      {"name": "name", "type": "string"},
      {"name": "age", "type": "int"}
    ]
  }
  """

  @long_person %{
    "name" => "luis",
    "age" => 25,
    "score" => 7.5
  }

  setup_all do
    {:ok, long_schema} = FastAvro.read_schema(@long_schema)
    {:ok, short_schema} = FastAvro.read_schema(@short_schema)
    {:ok, long_person} = FastAvro.encode_avro_datum(@long_person, long_schema)

    %{long_schema: long_schema, short_schema: short_schema, long_person: long_person}
  end

  test "decode avro datum should read all data", %{
    long_schema: long_schema,
    short_schema: short_schema,
    long_person: long_person
  } do
    assert {:ok, _} = FastAvro.decode_avro_datum(long_person, long_schema)
    assert {:error, :all_data_not_read} == FastAvro.decode_avro_datum(long_person, short_schema)
  end

  test "get raw value should read all data", %{
    long_schema: long_schema,
    short_schema: short_schema,
    long_person: long_person
  } do
    assert {:ok, _} = FastAvro.get_raw_value(long_person, long_schema, "name")
    assert {:error, :all_data_not_read} == FastAvro.get_raw_value(long_person, short_schema, "name")
  end
end
