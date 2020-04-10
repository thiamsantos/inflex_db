defmodule InflexDB do
  @moduledoc """
  Documentation for InflexDB.
  """

  alias InflexDB.{Authentication, Client, Point, HTTPRequest, HTTPClient, LineProtocol}

  @type error_response :: {:error, HTTPResponse.t()} | {:error, :econnrefused} | {:error, term()}

  @doc """
  Check the status of yout InfluxDB instance.

  ## Example

  ```elixir
  client = %InflexDB.Client{}

  InflexDB.ping(client)
  ```
  """
  @spec ping(client :: Client.t()) :: :ok | error_response()
  def ping(%Client{} = client) do
    request = %HTTPRequest{
      method: :get,
      base_url: client.url,
      path: "/ping"
    }

    request
    |> HTTPClient.request()
    |> handle_response()
  end

  @doc """
  Creates a new database.

  ## Example

  ```elixir
  client = %InflexDB.Client{}

  InflexDB.create_database(client, "mydb")
  ```
  """
  @spec create_database(client :: Client.t(), name :: String.t()) :: :ok | error_response()
  def create_database(%Client{} = client, name) when is_binary(name) do
    request = %HTTPRequest{
      method: :post,
      base_url: client.url,
      path: "/query",
      body: %{"q" => "CREATE DATABASE \"#{name}\";"},
      content_type: :urlencoded
    }

    request
    |> Authentication.with_credentials(client)
    |> HTTPClient.request()
    |> handle_response()
  end

  @doc """
  Deletes all of the data, measurements, series, continuous queries, and retention policies from the specified database.
  If you attempt to drop a database that does not exist, InfluxDB does not return an error.

  ## Example

  ```elixir
  client = %InflexDB.Client{}

  InflexDB.delete_database(client, "mydb")
  ```
  """
  @spec delete_database(client :: Client.t(), name :: String.t()) :: :ok | error_response()
  def delete_database(%Client{} = client, name) when is_binary(name) do
    request = %HTTPRequest{
      method: :post,
      base_url: client.url,
      path: "/query",
      body: %{"q" => "DROP DATABASE \"#{name}\";"},
      content_type: :urlencoded
    }

    request
    |> Authentication.with_credentials(client)
    |> HTTPClient.request()
    |> handle_response()
  end

  @doc """
  Returns a list of all databases on your instance.

  ```elixir
  client = %InflexDB.Client{}

  InflexDB.list_databases(client)
  # {:ok, ["_internal", "mydb"]}
  ```
  """
  @spec list_databases(client :: Client.t()) :: {:ok, [String.t()]} | error_response()
  def list_databases(%Client{} = client) do
    request = %HTTPRequest{
      method: :post,
      base_url: client.url,
      path: "/query",
      body: %{"q" => "SHOW DATABASES;"},
      content_type: :urlencoded
    }

    request
    |> Authentication.with_credentials(client)
    |> HTTPClient.request()
    |> handle_list_databases()
  end

  @spec write_points(client :: Client.t(), db :: String.t(), points :: [Point.t()]) ::
          :ok | error_response()
  def write_points(%Client{} = client, db, points) when is_binary(db) and is_list(points) do
    body = LineProtocol.encode(points)

    request = %HTTPRequest{
      method: :post,
      base_url: client.url,
      path: "/write",
      query: %{"db" => db},
      body: body,
      content_type: :text
    }

    request
    |> Authentication.with_credentials(client)
    |> HTTPClient.request()
    |> handle_response()
  end

  @spec write_point(client :: Client.t(), db :: String.t(), point :: Point.t()) ::
          :ok | error_response()
  def write_point(%Client{} = client, db, %Point{} = point) when is_binary(db) do
    write_points(client, db, [point])
  end

  @spec query(client :: Client.t(), db :: String.t(), query :: String.t()) ::
          {:ok, map()} | error_response()
  def query(%Client{} = client, db, query) when is_binary(db) and is_binary(query) do
    request = %HTTPRequest{
      method: :get,
      base_url: client.url,
      path: "/query",
      query: %{"db" => db, "q" => query}
    }

    request
    |> Authentication.with_credentials(client)
    |> HTTPClient.request()
    |> handle_query()
  end

  defp handle_response({:ok, %{status: 204}}), do: :ok
  defp handle_response({:ok, %{status: 200}}), do: :ok
  defp handle_response({:ok, response}), do: {:error, response}
  defp handle_response({:error, reason}), do: {:error, reason}

  defp handle_query({:ok, %{status: 200, body: body}}) do
    result =
      body
      |> Map.get("results")
      |> Enum.map(fn result ->
        result
        |> Map.get("series")
        |> Enum.map(fn series ->
          columns = Map.get(series, "columns")

          %{
            statement_id: Map.get(result, "statement_id"),
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
      end)
      |> List.flatten()

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
      |> Map.get("values", [])
      |> List.flatten()

    {:ok, result}
  end

  defp handle_list_databases({:ok, response}), do: {:error, response}
  defp handle_list_databases({:error, reason}), do: {:error, reason}
end
