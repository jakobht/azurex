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

    request = put_standard_headers(request, content_type)

    method = get_method(request)
    size = get_size(request)
    headers = get_headers_signature(request)
    uri_signature = get_uri_signature(request, storage_account_name)

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
        uri_signature
      ]
      |> Enum.join("\n")

    put_signature(request, signature, storage_account_name, storage_account_key)
  end

  defp put_standard_headers(request, content_type) do
    now =
      DateTime.utc_now()
      |> formatted()

    headers =
      if content_type,
        do: [{"content-type", content_type} | request.headers],
        else: request.headers

    headers = [
      {"x-ms-version", "2019-12-12"},
      {"x-ms-date", now}
      | headers
    ]

    struct(request, headers: headers)
  end

  def formatted(%DateTime{zone_abbr: "UTC"} = date_time) do
    date_time
    # We use Timex strftime, as Calendar.strftime in the std is only availible from Elixir 1.11
    |> Timex.Format.DateTime.Formatters.Strftime.format!("%a, %d %b %Y %H:%M:%S GMT")
  end

  defp get_method(request), do: request.method |> Atom.to_string() |> String.upcase()

  defp get_size(request) do
    size = request.body |> byte_size()
    if size != 0, do: size, else: ""
  end

  defp get_headers_signature(request) do
    request.headers
    |> Enum.map(fn {k, v} -> {String.downcase(k), v} end)
    |> Enum.filter(fn {k, _v} -> String.starts_with?(k, "x-ms-") end)
    |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.map(fn {k, v} ->
      v = v |> Enum.sort() |> Enum.join(",")
      k <> ":" <> v
    end)
    |> Enum.join("\n")
  end

  defp get_uri_signature(request, storage_account_name) do
    uri = URI.parse(request.url)
    path = uri.path || "/"
    query = URI.query_decoder(uri.query || "")

    [
      "/",
      storage_account_name,
      path
      | Enum.map(query, fn {k, v} ->
          ["\n", k, ":", v]
        end)
    ]
  end

  defp put_signature(request, signature, storage_account_name, storage_account_key) do
    signature =
      :crypto.mac(:hmac, :sha256, storage_account_key, signature)
      |> Base.encode64()

    authorization = {"authorization", "SharedKey #{storage_account_name}:#{signature}"}

    headers = [authorization | request.headers]
    struct(request, headers: headers)
  end
end
