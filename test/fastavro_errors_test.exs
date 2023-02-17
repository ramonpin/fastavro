defmodule FastavroErrorsTest do
  use ExUnit.Case

  @incompatible_person_schema """
  {
    "type": "record",
    "name": "test",
    "fields": [
      {"name": "name", "type": "string"},
      {"name": "age", "type": "string"},
      {"name": "score", "type": "double"}
    ]
  }
  """

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

  @map_person %{
    "name" => "luis",
    "age" => 25,
    "score" => 7.5
  }

  @avro_person <<8, 108, 117, 105, 115, 50, 0, 0, 0, 0, 0, 0, 30, 64>>

  test "A wrong schema gives an error" do
    {:error, reason} = FastAvro.read_schema("{}")

    assert reason == :bad_avro_schema
  end

  test "encode with an incompatible schema gives error" do
    {:ok, schema} = FastAvro.read_schema(@incompatible_person_schema)
    {:error, reason} = FastAvro.encode_avro_datum(@map_person, schema)

    assert reason == :incompatible_avro_schema
  end

  test "decode with an incompatible schema gives error" do
    {:ok, schema} = FastAvro.read_schema(@incompatible_person_schema)
    {:error, reason} = FastAvro.decode_avro_datum(@avro_person, schema)

    assert reason == :incompatible_avro_schema
  end

  test "get unknown field gives an error" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)
    {:ok, record} = FastAvro.decode_avro_datum(@avro_person, schema)
    assert {:error, :field_not_found} = FastAvro.get_avro_value(record, "wrong")
  end

  test "get raw value with an incompatible schema gives error" do
    {:ok, schema} = FastAvro.read_schema(@incompatible_person_schema)
    {:error, reason} = FastAvro.get_raw_value(@avro_person, schema, "name")

    assert reason == :incompatible_avro_schema
  end

  test "get value from unknown field gives an error" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)
    {:ok, avro_record} = FastAvro.decode_avro_datum(@avro_person, schema)

    assert {:error, :field_not_found} = FastAvro.get_avro_value(avro_record, "wrong")
  end

  test "get raw value for unknown field gives an error" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)
    assert {:error, :field_not_found} = FastAvro.get_raw_value(@avro_person, schema, "wrong")
  end
end
