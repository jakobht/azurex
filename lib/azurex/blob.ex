defmodule Azurex.Blob do
  @moduledoc """
  Implementation of Azure Blob Storage.

  In the functions below set container as nil to use the one configured in `Azurex.Blob.Config`.
  """

  alias Azurex.Blob.{Block, Config}
  alias Azurex.Authorization.SharedKey

  @spec list_containers(Config.config_overrides()) ::
          {:ok, String.t()}
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def list_containers(overrides \\ []) do
    %HTTPoison.Request{
      url: Config.api_url(overrides) <> "/",
      params: [comp: "list"]
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(overrides),
      storage_account_key: Config.storage_account_key(overrides)
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{body: xml, status_code: 200}} -> {:ok, xml}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Upload a blob.

  ## The `blob` Argument

  The blob argument may be either a `binary` or a tuple of
  `{:stream, Stream.t()}`.

  ## The `content_type` Argument

  This argument can be either a valid string, or `nil`. A `content_type`
  argument of `nil` will result in the blob being assigned the default content
  type `"application/octet-stream"`.

  ## The `options` Argument

  The last argument of this function is a keyword list that can contain the following options:
    * `params`: a list of additional query parameters to include in the request
    * `headers`: a list of additional headers to include in the request
    * any other options that can be passed to `HTTPoison.request/1`

  ## Examples

      iex> put_blob("filename.txt", "file contents", "text/plain")
      :ok

      iex> {:ok, io_device} = StringIO.open("file contents as a stream")
      byte_length = 8_000_000
      bitstream = IO.binstream(io_device, byte_length)
      put_blob("filename.txt", {:stream, bitstream}, nil)
      :ok

      iex> put_blob("filename.txt", "file contents", "text/plain", params: [timeout: 10])
      :ok

      iex> put_blob("filename.txt", "file contents", "text/plain", params: [timeout: 10], headers: [{"x-ms-meta-foo", "bar"}])
      iex> put_blob("filename.txt", "file contents", "text/plain", [container: "container"])
      :ok

      iex> put_blob("filename.txt", "file contents", "text/plain", [storage_account_name: "name", storage_account_key: "key"])
      :ok

      iex> put_blob("filename.txt", "file contents", "text/plain", [storage_account_connection_string: "AccountName=name;AccountKey=key", container: "container"])
      :ok

      iex> put_blob("filename.txt", "file contents", "text/plain")
      {:error, %HTTPoison.Response{}}

  """
  @spec put_blob(
          String.t(),
          binary() | {:stream, Enumerable.t()},
          String.t(),
          keyword()
        ) ::
          :ok
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def put_blob(name, blob, content_type, options \\ [])

  def put_blob(name, {:stream, bitstream}, content_type, options) do
    content_type = content_type || "application/octet-stream"

    bitstream
    |> Stream.transform(
      fn -> [] end,
      fn chunk, acc ->
        with {:ok, block_id} <- Block.put_block(chunk, name, options) do
          {[], [block_id | acc]}
        end
      end,
      fn acc ->
        Block.put_block_list(acc, name, content_type, options)
      end
    )
    |> Stream.run()
  end

  def put_blob(name, blob, content_type, options) do
    content_type = content_type || "application/octet-stream"
    {params, options} = Keyword.pop(options, :params, [])
    {headers, options} = Keyword.pop(options, :headers, [])
    headers = Enum.map(headers, fn {k, v} -> {to_string(k), v} end)
    {connection_params, options} = Config.get_connection_params(options)

    %HTTPoison.Request{
      method: :put,
      url: get_url(name, connection_params),
      params: params,
      body: blob,
      headers: [
        {"x-ms-blob-type", "BlockBlob"} | headers
      ],
      # Blob storage only answers when the whole file has been uploaded, so recv_timeout
      # is not applicable for the put request, so we set it to infinity
      options: [recv_timeout: :infinity] ++ options
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(connection_params),
      storage_account_key: Config.storage_account_key(connection_params),
      content_type: content_type
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{status_code: 201}} -> :ok
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Download a blob

  ## Examples

      iex> get_blob("filename.txt")
      {:ok, "file contents"}

      iex> get_blob("filename.txt", "container")
      {:ok, "file contents"}

      iex> get_blob("filename.txt", [storage_account_name: "name", storage_account_key: "key", container: "container"])
      {:ok, "file contents"}

      iex> get_blob("filename.txt", [storage_account_connection_string: "AccountName=name;AccountKey=key"])
      {:ok, "file contents"}

      iex> get_blob("filename.txt", nil, timeout: 10)
      {:ok, "file contents"}

      iex> get_blob("filename.txt", nil, timeout: 10, headers: [{"x-ms-range", "bytes=0-10"}])
      {:ok, "file contents"}

      iex> get_blob("filename.txt")
      {:error, %HTTPoison.Response{}}

  """
  @spec get_blob(String.t(), keyword) ::
          {:ok, binary()}
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def get_blob(name, options \\ []) do
    blob_request(name, :get, options)
    |> HTTPoison.request()
    |> case do
      {:ok, %{body: blob, status_code: 200}} -> {:ok, blob}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Checks if a blob exists, and returns metadata for the blob if it does
  """
  @spec head_blob(String.t(), keyword()) ::
          {:ok, list}
          | {:error, :not_found | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def head_blob(name, options \\ []) do
    blob_request(name, :head, options)
    |> HTTPoison.request()
    |> case do
      {:ok, %HTTPoison.Response{status_code: 200, headers: details}} -> {:ok, details}
      {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, :not_found}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Copies a blob to a destination.

  The same configuration options (connection string, container, ...) are applied to both source and destination.

  Note: Azure’s ‘[Copy Blob from URL](https://learn.microsoft.com/en-us/rest/api/storageservices/copy-blob-from-url)’
  operation has a maximum size of 256 MiB.
  """
  @spec copy_blob(String.t(), String.t(), Config.config_overrides()) ::
          {:ok, HTTPoison.Response.t()} | {:error, term()}
  def copy_blob(source_name, destination_name, overrides \\ []) do
    content_type = "application/octet-stream"
    {connection_params, _overrides} = Config.get_connection_params(overrides)
    source_url = get_url(source_name, connection_params)
    headers = [{"x-ms-copy-source", source_url}, {"content-type", content_type}]

    %HTTPoison.Request{
      method: :put,
      url: get_url(destination_name, connection_params),
      headers: headers
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(connection_params),
      storage_account_key: Config.storage_account_key(connection_params),
      content_type: content_type
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %HTTPoison.Response{status_code: 202} = resp} -> {:ok, resp}
      {:ok, %HTTPoison.Response{} = resp} -> {:error, resp}
      err -> err
    end
  end

  @spec delete_blob(String.t(), keyword()) ::
          :ok | {:error, :not_found | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def delete_blob(name, options \\ []) do
    blob_request(name, :delete, options)
    |> HTTPoison.request()
    |> case do
      {:ok, %HTTPoison.Response{status_code: 202}} -> :ok
      {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, :not_found}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  def blob_request(name, method, options) do
    {params, options} = Keyword.pop(options, :params, [])
    {headers, options} = Keyword.pop(options, :headers, [])
    {connection_params, options} = Config.get_connection_params(options)

    %HTTPoison.Request{
      method: method,
      url: get_url(name, connection_params),
      params: params,
      headers: headers,
      options: options
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(connection_params),
      storage_account_key: Config.storage_account_key(connection_params)
    )
  end

  @doc """
  Lists all blobs in a container

  ## Examples

      iex> Azurex.Blob.list_blobs()
      {:ok, "\uFEFF<?xml ...."}

      iex> Azurex.Blob.list_blobs(storage_account_name: "name", storage_account_key: "key", container: "container")
      {:ok, "\uFEFF<?xml ...."}

      iex> Azurex.Blob.list_blobs()
      {:error, %HTTPoison.Response{}}
  """
  @spec list_blobs(keyword()) ::
          {:ok, binary()}
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def list_blobs(options \\ []) do
    {params, options} = Keyword.pop(options, :params, [])
    {connection_params, _options} = Config.get_connection_params(options)

    %HTTPoison.Request{
      url: get_url(connection_params),
      params:
        [
          comp: "list",
          restype: "container"
        ] ++ params
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(connection_params),
      storage_account_key: Config.storage_account_key(connection_params)
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{body: xml, status_code: 200}} -> {:ok, xml}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Returns the url for a container (defaults to the one in `Azurex.Blob.Config`)
  """
  @spec get_url(keyword) :: String.t()
  def get_url(connection_params) do
    "#{Config.api_url(connection_params)}/#{get_container(connection_params)}"
  end

  @doc """
  Returns the url for a file in a container (defaults to the one in `Azurex.Blob.Config`)
  """
  @spec get_url(String.t(), keyword) :: String.t()
  def get_url(blob_name, connection_params) do
    "#{get_url(connection_params)}/#{blob_name}"
  end

  defp get_container(connection_params) do
    Keyword.get(connection_params, :container) || Config.default_container()
  end
end
