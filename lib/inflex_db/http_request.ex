defmodule InflexDB.HTTPRequest do
  @moduledoc false

  @enforce_keys [:method, :base_url, :path]
  defstruct method: nil,
            base_url: nil,
            query: %{},
            path: nil,
            body: %{},
            content_type: nil,
            headers: %{}
end
