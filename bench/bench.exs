defmodule Benches do
  def get() do
    {:ok, schm} = File.read!("bench/lte_202210.avsc") |> FastAvro.read_schema()
    data = File.read!("bench/lte_202210.avro")
    msg = FastAvro.decode_avro_datum(schm, data)

    Benchee.run(
      %{
        "get_first" => fn -> FastAvro.get_avro_value(msg, "Event_Start") end,
        "get_second" => fn -> FastAvro.get_avro_value(msg, "Event_Stop") end,
        "get_last" => fn -> FastAvro.get_avro_value(msg, "RNC_id") end
      },
      warmup: 2,
      time: 10,
      parallel: 3
    )

    nil
  end

  def raw_get do
    {:ok, schm} = File.read!("bench/lte_202210.avsc") |> FastAvro.read_schema()
    data = File.read!("bench/lte_202210.avro")

    Benchee.run(
      %{
        "avro" => fn ->
          schm
          |> FastAvro.decode_avro_datum(data)
          |> FastAvro.get_avro_value("Event_Stop")
        end,
        "raw" => fn ->
          schm
          |> FastAvro.get_raw_value(data, "Event_Stop")
        end
      },
      warmup: 2,
      time: 10,
      parallel: 3
    )

    nil
  end

  def encode do
    {:ok, schema} = File.read!("bench/lte_202210.avsc") |> FastAvro.read_schema()
    avro_map = File.read!("bench/lte_202210.json") |> Jason.decode!()

    Benchee.run(
      %{
        "encode" => fn -> FastAvro.encode_avro_datum(schema, avro_map) end
      },
      warmup: 2,
      time: 10,
      parallel: 3
    )

    nil
  end

  def to_map do
    {:ok, schema} = File.read!("bench/lte_202210.avsc") |> FastAvro.read_schema()
    data = File.read!("bench/lte_202210.avro")

    Benchee.run(
      %{
        "raw" => fn ->
          schema
          |> FastAvro.decode_avro_datum(data)
          |> FastAvro.to_map()
        end
      },
      warmup: 2,
      time: 10,
      parallel: 3
    )

    nil
  end

  def get_values do
    {:ok, schema} = File.read!("bench/lte_202210.avsc") |> FastAvro.read_schema()
    data = File.read!("bench/lte_202210.avro")

    Benchee.run(
      %{
        "get raw value three times" => fn ->
          [
            FastAvro.get_raw_value(schema, data, "Event_Start"),
            FastAvro.get_raw_value(schema, data, "Event_Stop"),
            FastAvro.get_raw_value(schema, data, "RNC_id")
          ]
        end,
        "get avro value three times" => fn ->
          msg = FastAvro.decode_avro_datum(schema, data)

          [
            FastAvro.get_avro_value(msg, "Event_Start"),
            FastAvro.get_avro_value(msg, "Event_Stop"),
            FastAvro.get_avro_value(msg, "RNC_id")
          ]
        end,
        "get three raw values" => fn ->
          FastAvro.get_raw_values(schema, data, ["Event_Start", "Event_Stop", "RNC_id"])
        end
      },
      warmup: 2,
      time: 10,
      parallel: 3
    )

    nil
  end

  def get_one_value do
    {:ok, schema} = File.read!("bench/lte_202210.avsc") |> FastAvro.read_schema()
    data = File.read!("bench/lte_202210.avro")

    Benchee.run(
      %{
        "get raw value" => fn ->
          [
            FastAvro.get_raw_value(schema, data, "Event_Stop")
          ]
        end,
        "get avro value" => fn ->
          msg = FastAvro.decode_avro_datum(schema, data)

          [
            FastAvro.get_avro_value(msg, "Event_Stop")
          ]
        end,
        "get one with raw values" => fn ->
          FastAvro.get_raw_values(schema, data, ["Event_Stop"])
        end
      },
      warmup: 2,
      time: 10,
      parallel: 3
    )

    nil
  end
end
