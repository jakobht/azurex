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
  def put_block(container, chunk, name, params) do
    block_id = build_block_id()
    content_type = "application/octet-stream"

    request =
      Req.new(
        method: :put,
        url: Blob.get_url(container, name),
        params: [{:comp, "block"}, {:blockid, block_id} | params],
        body: chunk,
        headers: [
          {"content-type", content_type},
          {"content-length", byte_size(chunk)}
        ]
      )

    request
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key(),
      content_type: content_type
    )
    |> Req.request()
    |> case do
      {:ok, %{status: 201}} -> {:ok, block_id}
      {:ok, response} -> {:error, response}
      {:error, exception} -> {:error, exception}
    end
  end

  @doc """
  Commits the given list of block_ids to a blob.

  Block IDs should be base64 encoded, as returned by put_block/2.
  """
  @spec put_block_list(list(), String.t(), String.t(), String.t() | nil, list()) ::
          :ok | {:error, term()}
  def put_block_list(block_ids, container, name, blob_content_type, params) do
    content_type = "text/plain; charset=UTF-8"
    blob_content_type = blob_content_type || "application/octet-stream"

    blocks =
      block_ids
      |> Enum.reverse()
      |> Enum.map_join("", fn block_id -> "<Uncommitted>#{block_id}</Uncommitted>" end)

    body = """
    <?xml version="1.0" encoding="utf-8"?>
    <BlockList>
    #{blocks}
    </BlockList>
    """

    request =
      Req.new(
        method: :put,
        url: Blob.get_url(container, name),
        params: [{:comp, "blocklist"} | params],
        body: body,
        headers: [
          {"content-type", content_type},
          {"x-ms-blob-content-type", blob_content_type}
        ]
      )

    request
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
