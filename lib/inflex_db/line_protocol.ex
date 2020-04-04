defmodule InflexDB.LineProtocol do
  @moduledoc false

  alias InflexDB.Point

  def encode(points) when is_list(points) do
    points
    |> Enum.map(fn %Point{} = point ->
      [
        String.replace(point.measurement, ~S( ), ~S(\ )) |> String.replace(~S(,), ~S(\,)),
        encode_tag_set(point.tag_set),
        " ",
        encode_field_set(point.field_set),
        encode_timestamp(point.timestamp)
      ]
    end)
    |> Enum.intersperse(?\n)
    |> IO.iodata_to_binary()
  end

  defp encode_tag_set(tag_set) when map_size(tag_set) == 0, do: []

  defp encode_tag_set(tag_set) when is_map(tag_set) do
    tags =
      tag_set
      |> Enum.map(fn {k, v} -> [escape(to_string(k)), ?=, escape(to_string(v))] end)
      |> Enum.intersperse(?,)

    [?,, tags]
  end

  defp encode_field_set(field_set) when is_map(field_set) do
    field_set
    |> Enum.map(fn {k, v} -> [escape(to_string(k)), ?=, encode_field_value(v)] end)
    |> Enum.intersperse(?,)
  end

  defp encode_timestamp(nil), do: []

  defp encode_timestamp(timestamp) when is_integer(timestamp) do
    [
      " ",
      to_string(timestamp)
    ]
  end

  defp encode_field_value(value) when is_integer(value), do: [to_string(value), ?i]
  defp encode_field_value(value) when is_float(value), do: to_string(value)
  defp encode_field_value(value) when is_boolean(value), do: to_string(value)

  defp encode_field_value(value) when is_binary(value) do
    [?", String.replace(value, ~S("), ~S(\")), ?"]
  end

  defp escape(value) do
    value
    |> String.replace(~S(,), ~S(\,))
    |> String.replace(~S(=), ~S(\=))
    |> String.replace(~S( ), ~S(\ ))
  end
end
