defmodule Azurex.Authorization.SharedKey do
  @moduledoc """
  Implements Azure Rest Api Authorization method.

  It is based on: https://docs.microsoft.com/en-us/rest/api/storageservices/authorize-with-shared-key
  As defined in 26 November 2019
  """

  @spec sign(HTTPoison.Request.t(), keyword) :: HTTPoison.Request.t()
  def sign(request, opts \\ []) do
    storage_account_name = Keyword.fetch!(opts, :storage_account_name)
    storage_account_key = Keyword.fetch!(opts, :storage_account_key)
    content_type = Keyword.get(opts, :content_type)
    date = Keyword.get(opts, :date, DateTime.utc_now())

    request = put_standard_headers(request, content_type, date)

    method = get_method(request)
    size = get_size(request)
    headers = format_headers(request.headers)
    uri = format_uri(request.url, storage_account_name)
    params = format_params(request.params)

    signature =
      [
        # HTTP Verb
        method,
        # Content-Encoding
        "",
        # Content-Language
        "",
        # Content-Length
        size,
        # Content-MD5
        "",
        # Content-Type
        content_type || "",
        # Date
        "",
        # If-Modified-Since
        "",
        # If-Match
        "",
        # If-None-Match
        "",
        # If-Unmodified-Since
        "",
        # Range
        "",
        # CanonicalizedHeaders
        headers,
        # CanonicalizedResource
        uri
        | params
      ]
      |> Enum.join("\n")

    put_signature(request, signature, storage_account_name, storage_account_key)
  end

  def put_standard_headers(request, content_type, date) do
    headers =
      if content_type,
        do: [{"content-type", content_type} | request.headers],
        else: request.headers

    headers = [
      {"x-ms-version", "2023-01-03"},
      {"x-ms-date", format_date(date)}
      | headers
    ]

    struct(request, headers: headers)
  end

  def format_date(%DateTime{zone_abbr: "UTC"} = date_time) do
    date_time
    |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT")
  end

  defp get_method(request), do: request.method |> Atom.to_string() |> String.upcase()

  defp get_size(request) do
    size = request.body |> byte_size()
    if size != 0, do: size, else: ""
  end

  defp format_headers(headers) do
    headers
    |> Enum.map(fn {k, v} -> {String.downcase(k), v} end)
    |> Enum.filter(fn {k, _v} -> String.starts_with?(k, "x-ms-") end)
    |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.map(fn {k, v} ->
      v = v |> Enum.sort() |> Enum.join(",")
      "#{k}:#{v}"
    end)
    |> Enum.join("\n")
  end

  defp format_uri(uri_str, storage_account_name) do
    path =
      URI.parse(uri_str)
      |> Map.get(:path, "/")

    [
      "/",
      storage_account_name,
      path
    ]
  end

  defp format_params(params) do
    params
    |> Enum.sort()
    |> Enum.map(fn {k, v} ->
      [to_string(k), ":", to_string(v)]
    end)
  end

  defp put_signature(request, signature, storage_account_name, storage_account_key) do
    signature =
      :crypto.mac(:hmac, :sha256, storage_account_key, signature)
      |> Base.encode64()

    authorization = {"Authorization", "SharedKey #{storage_account_name}:#{signature}"}

    headers = [authorization | request.headers]
    struct(request, headers: headers)
  end
end
