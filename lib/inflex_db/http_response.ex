defmodule InflexDB.HTTPResponse do
  keys = [:status, :headers, :body]
  @enforce_keys keys
  defstruct keys

  @type t :: %__MODULE__{
          status: integer(),
          headers: map(),
          body: String.t() | map()
        }
end
