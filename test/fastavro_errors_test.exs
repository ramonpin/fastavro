defmodule FastavroErrorsTest do
  use ExUnit.Case

  test "A wrong schema gives an error" do
    assert {:error, :bad_avro_schema} == FastAvro.read_schema("{}")
  end
end
