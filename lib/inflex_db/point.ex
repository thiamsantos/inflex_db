defmodule InflexDB.Point do
  @moduledoc """
  Struct represeting a point in InfluxDB.
  Checkout the line protocol [tutorial](https://docs.influxdata.com/influxdb/v1.7/write_protocols/line_protocol_tutorial/)
  and [reference](https://docs.influxdata.com/influxdb/v1.7/write_protocols/line_protocol_reference/) for more details.

  ## Example

  The following point:

  ```elixir
  %InflexDB.Point{
    measurement: "weather",
    tag_set: %{location: "us-midwest", season: "summer"},
    field_set: %{temperature: 82},
    timestamp: 1465839830100400200
  }
  ```

  Will produce the following InfluxDB point:
  ```
  weather,location=us-midwest,season=summer temperature=82 1465839830100400200
  ```
  """

  @enforce_keys [:measurement, :field_set]
  defstruct measurement: nil, tag_set: %{}, field_set: nil, timestamp: nil

  @type t :: %__MODULE__{
          measurement: String.t(),
          tag_set: map(),
          field_set: map(),
          timestamp: integer() | nil
        }
end
