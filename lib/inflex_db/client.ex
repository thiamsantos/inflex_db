defmodule InflexDB.Client do
  @moduledoc """
  The client connection.

  ## Url

  By default connects to localhost:8086. But it can be changed in the client struct.

  ```elixir
  %InflexDB.Client{url: "http:://myinfluxdbinstance:8086"}
  ```

  ## No authentication

  By default the client has no authentication method.

  ```elixir
  %InflexDB.Client{auth_method: "none"}
  ```

  ## Authenticate with Basic Authentication

  Checkout the [official InfluxDB docs](https://docs.influxdata.com/influxdb/v1.7/administration/authentication_and_authorization/#set-up-authentication)
  on how to set up authentication in the server.

  This is the preferred method for providing user credentials.
  Just set the `auth_method` option to `basic`.
  It will set the credentials as described in
  [RFC 2617, Section 2](https://tools.ietf.org/html/rfc2617#section-2)
  using the Authorization header in the request.

  ```elixir
  %InflexDB.Client{username: "admin", password: "admin", auth_method: "basic"}
  ```

  Is possible use query params to provide the credentials. Just set the `auth_method` option to `params`.

  ```elixir
  %InflexDB.Client{username: "admin", password: "admin", auth_method: "params"}
  ```

  ## Authenticate using JWT tokens

  To authenticate using JWT tokens first add
  [jose](https://github.com/potatosalad/erlang-jose) as dependency as
  it will be used to generate the tokens.

  ```elixir
  # mix.exs
  {:jose, "~> 1.10"},
  ```

  Then customize the client to incluse the shared secret and ttl in seconds of the tokens.

  ```elixir
  %InflexDB.Client{username: "admin", auth_method: "jwt", jwt_secret: "my super secret pass phrase", jwt_ttl: 60}
  ```

  Each request made with the library will generate a new short-lived jwt token with the ttl defined.

  Checkout the [official InfluxDB docs](https://docs.influxdata.com/influxdb/v1.7/administration/authentication_and_authorization/#authenticate-using-jwt-tokens)
  on how configure the support for JWT tokens in the server.

  """

  defstruct url: "http://localhost:8086",
            username: nil,
            password: nil,
            auth_method: "none",
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
