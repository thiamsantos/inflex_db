defmodule InflexDB do
  @moduledoc """
  Documentation for InflexDB.
  """

  alias InflexDB.{Client, Point, HTTPClient, LineProtocol}

  def ping(%Client{} = client) do
    client.url
    |> URI.parse()
    |> Map.put(:path, "/ping")
    |> HTTPClient.get()
    |> handle_response()
  end

  def create_database(%Client{} = client, name) when is_binary(name) do
    {query_params, headers} = auth_params(client)

    client.url
    |> URI.parse()
    |> Map.put(:path, "/query")
    |> Map.put(:query, URI.encode_query(query_params))
    |> HTTPClient.post(
      %{"q" => "CREATE DATABASE \"#{name}\";"},
      :urlencoded,
      headers
    )
    |> handle_response()
  end

  def write_points(%Client{} = client, db, points) when is_binary(db) and is_list(points) do
    body = LineProtocol.encode(points)
    {query_params, headers} = auth_params(client)

    client.url
    |> URI.parse()
    |> Map.put(:path, "/write")
    |> Map.put(:query, URI.encode_query(Map.merge(query_params, %{"db" => db})))
    |> HTTPClient.post(body, :text, headers)
    |> handle_response()
  end

  def write_point(%Client{} = client, db, %Point{} = point) when is_binary(db) do
    write_points(client, db, [point])
  end

  def query(%Client{} = client, db, query) when is_binary(db) and is_binary(query) do
    {query_params, headers} = auth_params(client)

    client.url
    |> URI.parse()
    |> Map.put(:path, "/query")
    |> Map.put(:query, URI.encode_query(Map.merge(query_params, %{"db" => db, "q" => query})))
    |> HTTPClient.get(headers)
    |> handle_query()
  end

  def list_databases(%Client{} = client) do
    {query_params, headers} = auth_params(client)

    client.url
    |> URI.parse()
    |> Map.put(:path, "/query")
    |> Map.put(:query, URI.encode_query(query_params))
    |> HTTPClient.post(
      %{"q" => "SHOW DATABASES;"},
      :urlencoded,
      headers
    )
    |> handle_list_databases()
  end

  defp handle_response({:ok, %{status: 204}}), do: :ok
  defp handle_response({:ok, %{status: 200}}), do:  :ok
  defp handle_response({:ok, response}), do: {:error, response}
  defp handle_response({:error, reason}), do: {:error, reason}

  defp handle_query({:ok, %{status: 200, body: body}}) do
    result =
      body
      |> Map.get("results")
      |> List.first()
      |> Map.get("series")
      |> Enum.map(fn series ->
        columns = Map.get(series, "columns")

        %{
          name: Map.get(series, "name"),
          tags: Map.get(series, "tags"),
          values:
            series
            |> Map.get("values")
            |> Enum.map(fn value ->
              columns
              |> Enum.with_index()
              |> Enum.map(fn {k, index} ->
                {k, Enum.at(value, index)}
              end)
              |> Map.new()
            end)
        }
      end)

    {:ok, result}
  end

  defp handle_query({:ok, response}), do: {:error, response}
  defp handle_query({:error, reason}), do: {:error, reason}

  defp handle_list_databases({:ok, %{status: 200, body: body}}) do
    result =
      body
      |> Map.get("results")
      |> List.first()
      |> Map.get("series")
      |> List.first()
      |> Map.get("values")
      |> List.flatten()

    {:ok, result}
  end

  defp handle_list_databases({:ok, response}), do: {:error, response}
  defp handle_list_databases({:error, reason}), do: {:error, reason}

  defp auth_params(%Client{auth_method: "none"}) do
    {%{}, %{}}
  end

  defp auth_params(%Client{auth_method: "basic", username: username, password: password}) when is_binary(username) and is_binary(password) do
    {%{}, %{"authorization" => "Basic " <> Base.encode64(username <> ":" <> password)}}
  end

  defp auth_params(%Client{auth_method: "params", username: username, password: password}) when is_binary(username) and is_binary(password) do
    {%{"u" => username, "p" => password}, %{}}
  end

  defp auth_params(%Client{auth_method: "jwt", username: username, jwt_secret: jwt_secret, jwt_ttl: jwt_ttl}) when is_binary(username) and is_binary(jwt_secret) and is_integer(jwt_ttl) and jwt_ttl > 0 do
    header = %{
      "alg" => "HS256",
      "typ" => "JWT"
    }

    epoch_now = DateTime.to_unix(DateTime.utc_now())

    payload = %{
      "username" => username,
      "exp" => epoch_now + jwt_ttl
    }

    {_, jwt_token} = jwt_secret |> JOSE.JWK.from_oct() |> JOSE.JWT.sign(header, payload) |> JOSE.JWS.compact()

    {%{}, %{"authorization" => "Bearer " <> jwt_token}}
  end
end
