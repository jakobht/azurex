defmodule Azurex.Blob do
  @moduledoc """
  Implementation of Azure Blob Storage.

  In the functions below set container as nil to use the one configured in `Azurex.Blob.Config`.
  """

  alias Azurex.Authorization.Auth
  alias Azurex.Blob.{Block, Config}

  @typep optional_string :: String.t() | nil

  def list_containers do
    %HTTPoison.Request{
      url: Config.api_url() <> "/",
      params: [comp: "list"]
    }
    |> Auth.authorize_request()
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
      {:error, %HTTPoison.Response{}}

  """
  @spec put_blob(
          String.t(),
          binary() | {:stream, Enumerable.t()},
          optional_string,
          optional_string,
          keyword
        ) ::
          :ok
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def put_blob(name, blob, content_type, container \\ nil, params \\ [])

  def put_blob(name, {:stream, bitstream}, content_type, container, params) do
    content_type = content_type || "application/octet-stream"

    bitstream
    |> Stream.transform(
      fn -> [] end,
      fn chunk, acc ->
        with {:ok, block_id} <- Block.put_block(container, chunk, name, params) do
          {[], [block_id | acc]}
        end
      end,
      fn acc ->
        Block.put_block_list(acc, container, name, content_type, params)
      end
    )
    |> Stream.run()
  end

  def put_blob(name, blob, content_type, container, params) do
    content_type = content_type || "application/octet-stream"

    %HTTPoison.Request{
      method: :put,
      url: get_url(container, name),
      params: params,
      body: blob,
      headers: [
        {"x-ms-blob-type", "BlockBlob"}
      ],
      # Blob storage only answers when the whole file has been uploaded, so recv_timeout
      # is not applicable for the put request, so we set it to infinity
      options: [recv_timeout: :infinity]
    }
    |> Auth.authorize_request(content_type)
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

      iex> get_blob("filename.txt", nil, timeout: 10)
      {:ok, "file contents"}

      iex> get_blob("filename.txt")
      {:error, %HTTPoison.Response{}}

  """
  @spec get_blob(String.t(), optional_string) ::
          {:ok, binary()}
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def get_blob(name, container \\ nil, params \\ []) do
    blob_request(name, container, :get, params)
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
  @spec head_blob(String.t(), optional_string) ::
          {:ok, list}
          | {:error, :not_found | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def head_blob(name, container \\ nil, params \\ []) do
    blob_request(name, container, :head, params)
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

  Note: Azure’s ‘[Copy Blob from URL](https://learn.microsoft.com/en-us/rest/api/storageservices/copy-blob-from-url)’
  operation has a maximum size of 256 MiB.
  """
  @spec copy_blob(String.t(), String.t(), optional_string) ::
          {:ok, HTTPoison.Response.t()} | {:error, term()}
  def copy_blob(source_name, destination_name, container \\ nil) do
    content_type = "application/octet-stream"
    source_url = get_url(container, source_name)
    headers = [{"x-ms-copy-source", source_url}, {"content-type", content_type}]

    %HTTPoison.Request{
      method: :put,
      url: get_url(container, destination_name),
      headers: headers
    }
    |> Auth.authorize_request(content_type)
    |> HTTPoison.request()
    |> case do
      {:ok, %HTTPoison.Response{status_code: 202} = resp} -> {:ok, resp}
      {:ok, %HTTPoison.Response{} = resp} -> {:error, resp}
      err -> err
    end
  end

  @spec delete_blob(String.t(), optional_string()) ::
          :ok | {:error, :not_found | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def delete_blob(name, container \\ nil, params \\ []) do
    blob_request(name, container, :delete, params)
    |> HTTPoison.request()
    |> case do
      {:ok, %HTTPoison.Response{status_code: 202}} -> :ok
      {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, :not_found}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  defp blob_request(name, container, method, params, headers \\ [], options \\ []) do
    %HTTPoison.Request{
      method: method,
      url: get_url(container, name),
      params: params,
      headers: headers,
      options: options
    }
    |> Auth.authorize_request()
  end

  @doc """
  Lists all blobs in a container

  ## Examples

      iex> Azurex.Blob.list_blobs()
      {:ok, "\uFEFF<?xml ...."}

      iex> Azurex.Blob.list_blobs()
      {:error, %HTTPoison.Response{}}
  """
  @spec list_blobs(optional_string) ::
          {:ok, binary()}
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def list_blobs(container \\ nil, params \\ []) do
    %HTTPoison.Request{
      url: "#{Config.api_url()}/#{get_container(container)}",
      params:
        [
          comp: "list",
          restype: "container"
        ] ++ params
    }
    |> Auth.authorize_request()
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
