defmodule InflexDB.HTTPClient do
  @moduledoc false

  alias InflexDB.{HTTPRequest, HTTPResponse}

  @supported_content_types [:urlencoded, :text]

  def request(%HTTPRequest{method: :get, base_url: base_url, path: path, headers: headers, query: query})
      when is_binary(base_url) and is_binary(path) and is_map(headers) and is_map(query) do
    uri = base_url |> URI.parse() |> Map.put(:path, path) |> Map.put(:query, URI.encode_query(query))

    :httpc.request(:get, {to_charlist(URI.to_string(uri)), encode_headers(headers)}, [], [])
    |> format_response()
  end

  def request(%HTTPRequest{
        method: :post,
        base_url: base_url,
        path: path,
        query: query,
        body: body,
        content_type: content_type,
        headers: headers
      })
      when is_binary(base_url) and is_binary(path) and is_map(query) and is_map(body) or is_binary(body) and
             content_type in @supported_content_types and is_map(headers) do
    uri =
      base_url
      |> URI.parse()
      |> Map.put(:path, path)
      |> Map.put(:query, URI.encode_query(query))

    :httpc.request(
      :post,
      {to_charlist(URI.to_string(uri)), encode_headers(headers), get_content_type(content_type),
       encode(body, content_type)},
      [],
      []
    )
    |> format_response()
  end

  defp encode_headers(headers) do
    Enum.map(headers, fn {k, v} -> {to_charlist(String.downcase(k)), to_charlist(v)} end)
  end

  defp get_content_type(:urlencoded), do: 'application/x-www-form-urlencoded'
  defp get_content_type(:text), do: 'text/plain'

  defp encode(body, :text), do: body
  defp encode(body, :urlencoded), do: URI.encode_query(body)

  defp format_response({:ok, {{_, status, _}, headers, body}}) do
    headers = format_headers(headers)
    content_type = Map.get(headers, "content-type")

    {:ok, %HTTPResponse{status: status, headers: headers, body: format_body(body, content_type)}}
  end

  defp format_response({:error, {:failed_connect, _}}), do: {:error, :econnrefused}
  defp format_response(response), do: response

  defp format_headers(headers) do
    headers
    |> Enum.map(fn {key, value} -> {String.downcase(to_string(key)), to_string(value)} end)
    |> Map.new()
  end

  defp format_body(data, content_type) when is_list(data) do
    data
    |> IO.iodata_to_binary()
    |> format_body(content_type)
  end

  defp format_body(data, "application/json") when is_binary(data) do
    case Jason.decode(data) do
      {:ok, decoded} -> decoded
      _ -> data
    end
  end

  defp format_body(data, _content_type) when is_binary(data), do: data
end
