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
    |> handle_write()
  end

  def create_database(%Client{} = client, name) when is_binary(name) do
    client.url
    |> URI.parse()
    |> Map.put(:path, "/query")
    |> HTTPClient.post(
      %{"q" => "CREATE DATABASE \"#{name}\";"},
      :urlencoded,
      build_headers(client)
    )
    |> handle_create_database()
  end

  def write_points(%Client{} = client, db, points) when is_binary(db) and is_list(points) do
    body = LineProtocol.encode(points)

    client.url
    |> URI.parse()
    |> Map.put(:path, "/write")
    |> Map.put(:query, URI.encode_query(%{"db" => db}))
    |> HTTPClient.post(body, :text, build_headers(client))
    |> handle_write()
  end

  def write_point(%Client{} = client, db, %Point{} = point) when is_binary(db) do
    write_points(client, db, [point])
  end

  def query(%Client{} = client, db, query) when is_binary(db) and is_binary(query) do
    client.url
    |> URI.parse()
    |> Map.put(:path, "/query")
    |> Map.put(:query, URI.encode_query(%{"db" => db, "q" => query}))
    |> HTTPClient.get(build_headers(client))
    |> handle_query()
  end

  defp handle_write({:ok, %{status: 204}}), do: :ok
  defp handle_write({:ok, response}), do: {:error, response}
  defp handle_write({:error, reason}), do: {:error, reason}

  defp handle_create_database({:ok, %{status: 200}}), do: :ok
  defp handle_create_database({:ok, response}), do: {:error, response}
  defp handle_create_database({:error, reason}), do: {:error, reason}

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

  defp build_headers(client) do
    %{"authorization" => "Basic " <> Base.encode64(client.username <> ":" <> client.password)}
  end
end
