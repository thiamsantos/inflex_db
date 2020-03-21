defmodule InflexDB.Authentication do
  @moduledoc false

  alias InflexDB.{Client, HTTPRequest}

  def with_credentials(%HTTPRequest{} = request, %Client{auth_method: "none"}) do
    request
  end

  def with_credentials(%HTTPRequest{headers: headers} = request, %Client{
        auth_method: "basic",
        username: username,
        password: password
      })
      when is_map(headers) and is_binary(username) and is_binary(password) do
    %{
      request
      | headers:
          Map.merge(headers, %{
            "authorization" => "Basic " <> Base.encode64(username <> ":" <> password)
          })
    }
  end

  def with_credentials(%HTTPRequest{query: query} = request, %Client{
        auth_method: "params",
        username: username,
        password: password
      })
      when is_map(query) and is_binary(username) and is_binary(password) do
    %{request | query: Map.merge(query, %{"u" => username, "p" => password})}
  end

  def with_credentials(%HTTPRequest{headers: headers} = request, %Client{
        auth_method: "jwt",
        username: username,
        jwt_secret: jwt_secret,
        jwt_ttl: jwt_ttl
      })
      when is_map(headers) and is_binary(username) and is_binary(jwt_secret) and
             is_integer(jwt_ttl) and jwt_ttl > 0 do
    header = %{
      "alg" => "HS256",
      "typ" => "JWT"
    }

    epoch_now = DateTime.to_unix(DateTime.utc_now())

    payload = %{
      "username" => username,
      "exp" => epoch_now + jwt_ttl
    }

    {_, jwt_token} =
      jwt_secret |> JOSE.JWK.from_oct() |> JOSE.JWT.sign(header, payload) |> JOSE.JWS.compact()

    %{request | headers: Map.merge(headers, %{"authorization" => "Bearer " <> jwt_token})}
  end
end
