defmodule Azurex.Blob.Block do
  @moduledoc """
  Implementation of Azure Blob Storage.

  You can:

  - [upload a block as part of a blob](https://learn.microsoft.com/en-us/rest/api/storageservices/put-block)
  - [commit a list of blocks as part of a blob](https://learn.microsoft.com/en-us/rest/api/storageservices/put-block-list)
  """

  alias Azurex.Authorization.Auth
  alias Azurex.Blob
  alias Azurex.Blob.Config

  @doc """
  Creates a block to be committed to a blob.

  On success, returns an :ok tuple with the base64 encoded block_id.
  """
  @spec put_block(Config.config_overrides(), bitstring(), String.t(), list()) ::
          {:ok, String.t()} | {:error, term()}
  def put_block(overrides \\ [], chunk, name, params) do
    block_id = build_block_id()
    content_type = "application/octet-stream"
    params = [{:comp, "block"}, {:blockid, block_id} | params]
    connection_params = Config.get_connection_params(overrides)

    %HTTPoison.Request{
      method: :put,
      url: Blob.get_url(name, connection_params),
      params: params,
      body: chunk,
      headers: [
        {"content-type", content_type},
        {"content-length", byte_size(chunk)}
      ]
    }
    |> Auth.authorize_request(connection_params, content_type)
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
  @spec put_block_list(list(), Config.config_overrides(), String.t(), String.t() | nil, list()) ::
          :ok | {:error, term()}
  def put_block_list(block_ids, overrides \\ [], name, blob_content_type, params) do
    params = [{:comp, "blocklist"} | params]
    content_type = "text/plain; charset=UTF-8"
    blob_content_type = blob_content_type || "application/octet-stream"
    connection_params = Config.get_connection_params(overrides)

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
      url: Blob.get_url(name, connection_params),
      params: params,
      body: body,
      headers: [
        {"content-type", content_type},
        {"x-ms-blob-content-type", blob_content_type}
      ]
    }
    |> Auth.authorize_request(connection_params, content_type)
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
