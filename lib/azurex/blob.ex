defmodule Azurex.Blob do
  @moduledoc """
  Implementation of Azure Blob Storage.

  In the functions below set container as nil to use the one configured in `Azurex.Blob.Config`.
  """

  alias Azurex.Authorization.SharedKey
  alias Azurex.Blob.{Block, Config}

  @typep optional_string :: String.t() | nil

  def list_containers do
    Req.new(
      url: Config.api_url() <> "/",
      params: [comp: "list"]
    )
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key()
    )
    |> Req.request()
    |> case do
      {:ok, %{status: 200, body: xml}} -> {:ok, xml}
      {:ok, response} -> {:error, response}
      {:error, exception} -> {:error, exception}
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

  ## Examples

      iex> put_blob("filename.txt", "file contents", "text/plain")
      :ok

      iex> {:ok, io_device} = StringIO.open("file contents as a stream")
      byte_length = 8_000_000
      bitstream = IO.binstream(io_device, byte_length)
      put_blob("filename.txt", {:stream, bitstream}, nil)
      :ok

      iex> put_blob("filename.txt", "file contents", "text/plain", "container")
      :ok

      iex> put_blob("filename.txt", "file contents", "text/plain", nil, timeout: 10)
      :ok

      iex> put_blob("filename.txt", "file contents", "text/plain")
      {:error, %Req.Response{}}

  """
  @spec put_blob(
          String.t(),
          binary() | {:stream, Enumerable.t()},
          optional_string,
          optional_string,
          keyword
        ) ::
          :ok
          | {:error, term()}
  def put_blob(name, blob, content_type, container \\ nil, params \\ [])

  def put_blob(name, {:stream, bitstream}, content_type, container, params) do
    content_type = content_type || "application/octet-stream"

    bitstream
    |> Stream.transform(
      # Initialize with a success tuple
      fn -> {:ok, []} end,
      fn chunk, {:ok, acc} ->
        case Block.put_block(container, chunk, name, params) do
          {:ok, block_id} -> {[], {:ok, [block_id | acc]}}
          # Preserve the error
          {:error, error} -> {[], {:error, error}}
        end
      end,
      fn
        {:ok, block_ids} -> Block.put_block_list(block_ids, container, name, content_type, params)
        # Return the error instead of trying to process it
        {:error, error} -> {:error, error}
      end
    )
    |> Stream.run()
  end

  def put_blob(name, blob, content_type, container, params) do
    content_type = content_type || "application/octet-stream"

    Req.new(
      method: :put,
      url: get_url(container, name),
      params: params,
      body: blob,
      headers: [
        {"x-ms-blob-type", "BlockBlob"}
      ],
      # Blob storage only answers when the whole file has been uploaded
      receive_timeout: :infinity
    )
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key(),
      content_type: content_type
    )
    |> Req.request()
    |> case do
      {:ok, %{status: 201}} -> :ok
      {:ok, response} -> {:error, response}
      {:error, exception} -> {:error, exception}
    end
  end

  @doc """
  Download a blob

  ## Examples

      iex> get_blob("filename.txt")
      {:ok, "file contents"}

      iex> get_blob("filename.txt", "container")
      {:ok, "file contents"}

      iex> get_blob("filename.txt", nil, timeout: 10)
      {:ok, "file contents"}

      iex> get_blob("filename.txt")
      {:error, %Req.Response{}}

  """
  @spec get_blob(String.t(), optional_string, keyword()) ::
          {:ok, binary()}
          | {:error, term()}
  def get_blob(name, container \\ nil, params \\ []) do
    blob_request(name, container, :get, params)
    |> Req.request()
    |> case do
      {:ok, %{status: 200, body: blob}} -> {:ok, blob}
      {:ok, response} -> {:error, response}
      {:error, exception} -> {:error, exception}
    end
  end

  @doc """
  Checks if a blob exists, and returns metadata for the blob if it does
  """
  @spec head_blob(String.t(), optional_string, keyword()) ::
          {:ok, list}
          | {:error, :not_found | term()}
  def head_blob(name, container \\ nil, params \\ []) do
    blob_request(name, container, :head, params)
    |> Req.request()
    |> case do
      {:ok, %{status: 200, headers: headers}} -> {:ok, headers}
      {:ok, %{status: 404}} -> {:error, :not_found}
      {:ok, response} -> {:error, response}
      {:error, exception} -> {:error, exception}
    end
  end

  @doc """
  Copies a blob to a destination.
  """
  @spec copy_blob(String.t(), String.t(), optional_string) ::
          {:ok, term()} | {:error, term()}
  def copy_blob(source_name, destination_name, container \\ nil) do
    content_type = "application/octet-stream"
    source_url = get_url(container, source_name)

    Req.new(
      method: :put,
      url: get_url(container, destination_name),
      headers: [
        {"x-ms-copy-source", source_url},
        {"content-type", content_type}
      ]
    )
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key(),
      content_type: content_type
    )
    |> Req.request()
    |> case do
      {:ok, %{status: 202} = resp} -> {:ok, resp}
      {:ok, response} -> {:error, response}
      {:error, exception} -> {:error, exception}
    end
  end

  @spec delete_blob(String.t(), optional_string(), keyword()) ::
          :ok | {:error, :not_found | term()}
  def delete_blob(name, container \\ nil, params \\ []) do
    blob_request(name, container, :delete, params)
    |> Req.request()
    |> case do
      {:ok, %{status: 202}} -> :ok
      {:ok, %{status: 404}} -> {:error, :not_found}
      {:ok, response} -> {:error, response}
      {:error, exception} -> {:error, exception}
    end
  end

  defp blob_request(name, container, method, params, headers \\ []) do
    request =
      Req.new(
        method: method,
        url: get_url(container, name),
        params: params,
        headers: headers,
        decode_body: false
      )

    SharedKey.sign(
      request,
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key()
    )
  end

  @doc """
  Lists all blobs in a container

  ## Examples

      iex> Azurex.Blob.list_blobs()
      {:ok, "\uFEFF<?xml ...."}

      iex> Azurex.Blob.list_blobs()
      {:error, %Req.Response{}}
  """
  @spec list_blobs(optional_string, keyword()) ::
          {:ok, binary()}
          | {:error, term()}
  def list_blobs(container \\ nil, params \\ []) do
    Req.new(
      url: "#{Config.api_url()}/#{get_container(container)}",
      params:
        [
          comp: "list",
          restype: "container"
        ] ++ params
    )
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key()
    )
    |> Req.request()
    |> case do
      {:ok, %{status: 200, body: xml}} -> {:ok, xml}
      {:ok, response} -> {:error, response}
      {:error, exception} -> {:error, exception}
    end
  end

  @doc """
  Returns the url for a container (defaults to the one in `Azurex.Blob.Config`)
  """
  @spec get_url(optional_string) :: String.t()
  def get_url(container) do
    "#{Config.api_url()}/#{get_container(container)}"
  end

  @doc """
  Returns the url for a file in a container (defaults to the one in `Azurex.Blob.Config`)
  """
  @spec get_url(optional_string, String.t()) :: String.t()
  def get_url(container, blob_name) do
    "#{get_url(container)}/#{blob_name}"
  end

  defp get_container(container) do
    container || Config.default_container()
  end
end
