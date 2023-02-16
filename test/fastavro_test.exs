defmodule FastavroTest do
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

  @person_new_schema """
  {
    "type": "record",
    "name": "test",
    "fields": [
      {"name": "years", "type": "int"},
      {"name": "score_normalized", "type": "int"}
    ]
  }
  """

  @map_person %{
    "name" => "luis",
    "age" => 25,
    "score" => 7.5
  }

  @avro_person <<8, 108, 117, 105, 115, 50, 0, 0, 0, 0, 0, 0, 30, 64>>

  test "a schema can be read and fields extracted" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)
    assert is_reference(schema)

    fields = FastAvro.schema_fields(schema)
    assert fields == %{"age" => "Int", "name" => "String", "score" => "Double"}
  end

  test "a map can be encoded with a compatible schema" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)
    avro_datum = FastAvro.encode_avro_datum(@map_person, schema)

    assert is_binary(avro_datum)
    assert avro_datum == @avro_person
  end

  test "an avro datum can be decoded with a compatible schema" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)
    {:ok, avro_record} = FastAvro.decode_avro_datum(@avro_person, schema)

    assert is_reference(avro_record)
    assert FastAvro.to_map(avro_record) == @map_person
  end

  test "fields can be get from an avro record" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)
    {:ok, avro_record} = FastAvro.decode_avro_datum(@avro_person, schema)

    assert FastAvro.get_avro_value(avro_record, "name") == "luis"
    assert FastAvro.get_avro_value(avro_record, "age") == 25
    assert FastAvro.get_avro_value(avro_record, "score") == 7.5
    assert FastAvro.get_avro_value(avro_record, "wrong") == :field_not_found
  end

  test "fields can be get from avro row data and compatible schema" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)

    assert FastAvro.get_raw_value(@avro_person, schema, "name") == "luis"
    assert FastAvro.get_raw_value(@avro_person, schema, "age") == 25
    assert FastAvro.get_raw_value(@avro_person, schema, "score") == 7.5
    assert FastAvro.get_raw_value(@avro_person, schema, "wrong") == :field_not_found
  end

  test "several fields can be get from avro row data and compatible schema at once" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)

    assert FastAvro.get_raw_values(@avro_person, schema, ["age", "name"]) == %{
             "name" => "luis",
             "age" => 25
           }
  end

  test "functions can be piped to reencode data" do
    {:ok, schema} = FastAvro.read_schema(@person_schema)
    {:ok, new_schema} = FastAvro.read_schema(@person_new_schema)

    new_avro_person =
      @avro_person
      |> FastAvro.get_raw_values(schema, [
        "age",
        "score"
      ])
      |> Map.new(fn
        {"age", v} -> {"years", 1970 + v}
        {"score", v} -> {"score_normalized", trunc(v * 10)}
      end)
      |> FastAvro.encode_avro_datum(new_schema)
      |> FastAvro.decode_avro_datum(new_schema)
      |> elem(1)
      |> FastAvro.to_map()

    assert new_avro_person == %{"years" => 1995, "score_normalized" => 75}
  end
end
