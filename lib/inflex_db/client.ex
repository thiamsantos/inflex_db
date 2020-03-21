defmodule InflexDB.Client do
  defstruct url: nil,
            username: nil,
            password: nil,
            auth_method: "basic",
            jwt_secret: nil,
            jwt_ttl: nil
end
