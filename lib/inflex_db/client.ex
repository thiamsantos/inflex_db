defmodule InflexDB.Client do
  @enforce_keys [:url]
  defstruct url: nil,
            username: nil,
            password: nil,
            auth_method: "basic",
            jwt_secret: nil,
            jwt_ttl: nil

  @type t :: %__MODULE__{
          url: String.t(),
          username: String.t() | nil,
          password: String.t() | nil,
          auth_method: String.t(),
          jwt_secret: String.t() | nil,
          jwt_ttl: String.t() | nil
        }
end
