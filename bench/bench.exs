defmodule Benches do
  def get() do
    {:ok, schema} = File.read!("bench/lte_202210.avsc") |> FastAvro.read_schema()
    {:ok, data = File.read!("bench/lte_202210.avro")}
    msg = FastAvro.decode_avro_datum(schema, data)

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
    {:ok, schema} = File.read!("bench/lte_202210.avsc") |> FastAvro.read_schema()
    data = File.read!("bench/lte_202210.avro")

    Benchee.run(
      %{
        "avro" => fn ->
          data
          |> FastAvro.decode_avro_datum(schema)
          |> elem(1)
          |> FastAvro.get_avro_value("Event_Stop")
        end,
        "raw" => fn ->
          data
          |> FastAvro.get_raw_value(schema, "Event_Stop")
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
          data
          |> FastAvro.decode_avro_datum(schema)
          |> elem(1)
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
            FastAvro.get_raw_value(data, schema, "Event_Start"),
            FastAvro.get_raw_value(data, schema, "Event_Stop"),
            FastAvro.get_raw_value(data, schema, "RNC_id")
          ]
        end,
        "get avro value three times" => fn ->
          {:ok, msg} = FastAvro.decode_avro_datum(data, schema)

          [
            FastAvro.get_avro_value(msg, "Event_Start"),
            FastAvro.get_avro_value(msg, "Event_Stop"),
            FastAvro.get_avro_value(msg, "RNC_id")
          ]
        end,
        "get three raw values" => fn ->
          FastAvro.get_raw_values(data, schema, ["Event_Start", "Event_Stop", "RNC_id"])
        end
      },
      warmup: 2,
      time: 10,
      parallel: 3
    )

    nil
  end

  def get_one_value(n) when is_integer(n) do
    {:ok, schema} = File.read!("bench/lte_202210.avsc") |> FastAvro.read_schema()
    data = File.read!("bench/lte_202210.avro")

    Benchee.run(
      %{
        "get raw value" => fn ->
          FastAvro.get_raw_value(data, schema, "Event_Stop")
        end,
        "get avro value" => fn ->
          {:ok, msg} = FastAvro.decode_avro_datum(data, schema)
          FastAvro.get_avro_value(msg, "Event_Stop")
        end,
        "get one with raw values" => fn ->
          FastAvro.get_raw_values(data, schema, ["Event_Stop"])
        end
      },
      warmup: 2,
      time: 10,
      parallel: n
    )

    nil
  end
end
