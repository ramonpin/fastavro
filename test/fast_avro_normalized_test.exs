defmodule FastAvroNormalizedTest do
  use ExUnit.Case

  @person_schema """
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

  @avro_person <<8, 108, 117, 105, 115, 50, 0, 0, 0, 0, 0, 0, 30, 64, 15, 22, 33>>
  @avro_normalized_person <<8, 108, 117, 105, 115, 50, 0, 0, 0, 0, 0, 0, 30, 64>>

  test "fields can be get from avro data and compatible schema and avro data normalized" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)

    assert {:ok, {"luis", @avro_normalized_person}} ==
             FastAvro.normalize_and_get_raw_value(@avro_person, schema, "name")

    assert {:ok, {25, @avro_normalized_person}} ==
             FastAvro.normalize_and_get_raw_value(@avro_person, schema, "age")

    assert {:ok, {7.5, @avro_normalized_person}} =
             FastAvro.normalize_and_get_raw_value(@avro_person, schema, "score")
  end
end
