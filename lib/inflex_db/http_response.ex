defmodule InflexDB.HTTPResponse do
  @moduledoc """
  Struct representing a HTTP response from InfluxDB.
  """
  keys = [:status, :headers, :body]
  @enforce_keys keys
  defstruct keys

  @type t :: %__MODULE__{
          status: integer(),
          headers: map(),
          body: String.t() | map()
        }
end
