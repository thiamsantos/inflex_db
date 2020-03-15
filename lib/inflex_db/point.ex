defmodule InflexDB.Point do
  @enforce_keys [:measurement]
  defstruct measurement: nil, tag_set: %{}, field_set: nil, timestamp: nil
end

# weather,location=us-midwest temperature=82 1465839830100400200
# |measurement|,tag_set| |field_set| |timestamp|
# For best performance you should sort tags by key before sending them to the database.
# Every data point requires at least one field in line protocol.
# If you do not specify a timestamp for your data point InfluxDB uses the server’s local nanosecond timestamp in UTC.
# nanosecond-precision

# Field values can be floats, integers, strings, or Booleans:

# Integers - append an i to the field value to tell InfluxDB to store the number as an integer.

# Measurements, tag keys, tag values, and field keys are always strings.

# Strings - double quote string field values (more on quoting in line protocol below).
# https://docs.influxdata.com/influxdb/v1.7/write_protocols/line_protocol_tutorial/#quoting
# Booleans - specify TRUE with t, T, true, True, or TRUE. Specify FALSE with f, F, false, False, or FALSE. Use `true` and `false`.
# Do double quote field values that are strings.

# when is_float()
# when is_integer()
# when is_binary()
# when is_boolean()

# escape For tag keys, tag values, and field keys

# commas ,
# equal signs =
# spaces

# For measurements always use a backslash character \ to escape:
# commas ,
# spaces

# For string field values use a backslash character \ to escape:

# double quotes "

# https://docs.influxdata.com/influxdb/v1.7/tools/api/#write-http-endpoint

# https://docs.influxdata.com/influxdb/v1.7/write_protocols/line_protocol_tutorial/#special-characters-and-keywords

# https://github.com/influxdata/influxdb-ruby/blob/cf93ad766091749a81b85781242c1b7bd6b8da4e/lib/influxdb/point_value.rb
