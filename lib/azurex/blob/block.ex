defmodule Azurex.Blob.Block do
  @moduledoc """
  Implementation of Azure Blob Storage.

  You can:

  - [upload a block as part of a blob](https://learn.microsoft.com/en-us/rest/api/storageservices/put-block)
  - [commit a list of blocks as part of a blob](https://learn.microsoft.com/en-us/rest/api/storageservices/put-block-list)
  """

  alias Azurex.Authorization.SharedKey
  alias Azurex.Blob
  alias Azurex.Blob.Config

  @doc """
  Creates a block to be committed to a blob.

  On success, returns an :ok tuple with the base64 encoded block_id.
  """
  @spec put_block(String.t(), bitstring(), String.t(), list()) ::
          {:ok, String.t()} | {:error, term()}
  def put_block(container, chunk, name, options) do
    block_id = build_block_id()
    content_type = "application/octet-stream"
    {params, options} = Keyword.pop(options, :params, [])
    {headers, options} = Keyword.pop(options, :headers, [])
    headers = Enum.map(headers, fn {k, v} -> {to_string(k), v} end)
    params = [{:comp, "block"}, {:blockid, block_id} | params]

    %HTTPoison.Request{
      method: :put,
      url: Blob.get_url(container, name),
      params: params,
      body: chunk,
      headers: [
        {"content-type", content_type},
        {"content-length", byte_size(chunk)} | headers
      ],
      options: options
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key(),
      content_type: content_type
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %HTTPoison.Response{status_code: 201}} -> {:ok, block_id}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Commits the given list of block_ids to a blob.

  Block IDs should be base64 encoded, as returned by put_block/2.
  """
  @spec put_block_list(list(), String.t(), String.t(), String.t() | nil, list()) ::
          :ok | {:error, term()}
  def put_block_list(block_ids, container, name, blob_content_type, options) do
    {params, options} = Keyword.pop(options, :params, [])
    {headers, options} = Keyword.pop(options, :headers, [])
    headers = Enum.map(headers, fn {k, v} -> {to_string(k), v} end)
    params = [{:comp, "blocklist"} | params]
    content_type = "text/plain; charset=UTF-8"
    blob_content_type = blob_content_type || "application/octet-stream"

    blocks =
      block_ids
      |> Enum.reverse()
      |> Enum.map(fn block_id -> "<Uncommitted>#{block_id}</Uncommitted>" end)
      |> Enum.join()

    body = """
    <?xml version="1.0" encoding="utf-8"?>
    <BlockList>
    #{blocks}
    </BlockList>
    """

    %HTTPoison.Request{
      method: :put,
      url: Blob.get_url(container, name),
      params: params,
      body: body,
      headers: [
        {"content-type", content_type},
        {"x-ms-blob-content-type", blob_content_type} | headers
      ],
      options: options
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key(),
      content_type: content_type
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %HTTPoison.Response{status_code: 201}} -> :ok
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  defp build_block_id do
    gen_half = fn ->
      4_294_967_296
      |> :rand.uniform()
      |> Integer.to_string(32)
      |> String.pad_trailing(8, "0")
    end

    (gen_half.() <> gen_half.())
    |> Base.encode64()
  end
end
