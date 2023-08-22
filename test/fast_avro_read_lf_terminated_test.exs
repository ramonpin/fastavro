defmodule FastAvroReadLFTerminatedTest do
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

  @map_person %{
    "name" => "luis",
    "age" => 25,
    "score" => 7.5
  }

  @avro_person <<8, 108, 117, 105, 115, 50, 0, 0, 0, 0, 0, 0, 30, 64, 10>>

  test "an avro datum can be decoded with a compatible schema" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)
    {:ok, avro_record} = FastAvro.decode_avro_datum(@avro_person, schema)

    assert is_reference(avro_record)
    assert FastAvro.to_map(avro_record) == @map_person
  end

  test "fields can be get from an avro record" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)
    {:ok, avro_record} = FastAvro.decode_avro_datum(@avro_person, schema)

    assert {:ok, "luis"} = FastAvro.get_avro_value(avro_record, "name")
    assert {:ok, 25} = FastAvro.get_avro_value(avro_record, "age")
    assert {:ok, 7.5} = FastAvro.get_avro_value(avro_record, "score")
    assert {:error, :field_not_found} = FastAvro.get_avro_value(avro_record, "wrong")
  end

  test "fields can be get from avro row data and compatible schema" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)

    assert {:ok, "luis"} == FastAvro.get_raw_value(@avro_person, schema, "name")
    assert {:ok, 25} == FastAvro.get_raw_value(@avro_person, schema, "age")
    assert {:ok, 7.5} = FastAvro.get_raw_value(@avro_person, schema, "score")
  end

  test "several fields can be get from avro row data and compatible schema at once" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)

    result = FastAvro.get_raw_values(@avro_person, schema, ["age", "name"])

    with {:ok, values} <- result do
      assert %{"name" => "luis", "age" => 25} == values
      assert length(Map.keys(values)) == 2
    end
  end
end
