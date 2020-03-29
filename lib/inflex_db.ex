defmodule InflexDB do
  @moduledoc """
  Documentation for InflexDB.
  """

  alias InflexDB.{Authentication, Client, Point, HTTPRequest, HTTPClient, LineProtocol}

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

  def write_point(%Client{} = client, db, %Point{} = point) when is_binary(db) do
    write_points(client, db, [point])
  end

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
      |> Map.get("values", [])
      |> List.flatten()

    {:ok, result}
  end

  defp handle_list_databases({:ok, response}), do: {:error, response}
  defp handle_list_databases({:error, reason}), do: {:error, reason}
end
