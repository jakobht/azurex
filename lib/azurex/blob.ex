defmodule Azurex.Blob do
  @moduledoc """
  Implementation of Azure Blob Storage.

  In the functions below set container as nil to use the one configured in `Azurex.Blob.Config`.
  """
  alias Azurex.Blob.Config
  alias Azurex.Authorization.SharedKey

  @typep optional_string :: String.t() | nil

  def list_containers do
    %HTTPoison.Request{
      url: Config.api_url() <> "/",
      params: [comp: "list"]
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key()
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

  ## Examples

      iex> put_blob("filename.txt", "file contents", "text/plain")
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
          String.t(),
          optional_string,
          keyword
        ) ::
          :ok
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def put_blob(name, blob, content_type, container \\ nil, params \\ [])

  def put_blob(name, {:stream, bitstream}, _content_type, container, params) do
    Stream.transform(
      bitstream,
      fn -> [] end,
      fn chunk, acc ->
        with {:ok, block_id} <- put_block(container, chunk, name, params) do
          {[], [block_id | acc]}
        end
      end,
      fn acc ->
        commit_block_list(acc, container, name, params)
      end
    )
    |> Enum.each(&IO.inspect(&1))
  end

  def put_blob(name, blob, content_type, container, params) do
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
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key(),
      content_type: content_type
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{status_code: 201}} -> :ok
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  defp put_block(container, chunk, name, params) do
    block_id = (build_block_id() <> build_block_id()) |> Base.encode64()
    content_type = "application/octet-stream"
    params = [{:comp, "block"}, {:blockid, block_id} | params]

    %HTTPoison.Request{
      method: :put,
      url: get_url(container, name),
      params: params,
      body: chunk,
      headers: [
        {"content-type", content_type}
      ]
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key(),
      content_type: content_type
    )
    |> HTTPoison.request()
    |> IO.inspect()
    |> case do
      {:ok, %{status_code: 201}} -> {:ok, block_id}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  defp build_block_id do
    4_294_967_296
    |> :rand.uniform()
    |> Integer.to_string(32)
  end

  defp commit_block_list(block_list, container, name, params) do
    params = [{:comp, "blocklist"} | params]

    blocks =
      block_list
      |> Enum.map(fn block_id -> "<Uncommitted>#{block_id}</Uncommitted>" end)
      |> Enum.join()

    body = "<Blocklist>#{blocks}</Blocklist>"

    %HTTPoison.Request{
      method: :put,
      url: get_url(container, name),
      params: params,
      body: body
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key()
    )
    |> HTTPoison.request()
    |> IO.inspect()
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
    blob_request(name, container, params)
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
    blob_request(name, container, params, [], :head)
    |> HTTPoison.request()
    |> case do
      {:ok, %HTTPoison.Response{status_code: 200, headers: details}} -> {:ok, details}
      {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, :not_found}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  defp blob_request(name, container, params, options \\ [], method \\ :get) do
    %HTTPoison.Request{
      method: method,
      url: get_url(container, name),
      params: params,
      options: options
    }
    |> SharedKey.sign(
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
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key()
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
