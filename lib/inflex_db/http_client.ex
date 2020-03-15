defmodule InflexDB.HTTPClient do
  @moduledoc false

  alias InflexDB.HTTPResponse

  def get(%URI{} = url, headers \\ %{}) do
    :httpc.request(:get, {to_charlist(URI.to_string(url)), encode_headers(headers)}, [], [])
    |> format_response()
  end

  def post(%URI{} = url, body, content_type, headers \\ %{}) do
    :httpc.request(
      :post,
      {to_charlist(URI.to_string(url)), encode_headers(headers), get_content_type(content_type),
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
