defmodule Azurex.Blob.Block do
  @moduledoc """
  Implementation of Azure Blob Storage
  """

  alias Azurex.Authorization.SharedKey
  alias Azurex.Blob
  alias Azurex.Blob.Config

  @doc """
  Creates a block to be committed to a blob.
  """
  @spec put_block(String.t(), bitstring(), String.t(), list()) ::
          {:ok, String.t()} | {:error, term()}
  def put_block(container, chunk, name, params) do
    block_id = build_block_id()
    content_type = "application/octet-stream"
    params = [{:comp, "block"}, {:blockid, block_id} | params]

    %HTTPoison.Request{
      method: :put,
      url: Blob.get_url(container, name),
      params: params,
      body: chunk,
      headers: [
        {"content-type", content_type},
        {"content-length", byte_size(chunk)}
      ]
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
  """
  @spec commit_list(list(), String.t(), String.t(), list()) :: :ok | {:error, term()}
  def commit_list(block_ids, container, name, params) do
    params = [{:comp, "blocklist"} | params]
    content_type = "text/plain; charset=UTF-8"

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
        {"content-type", content_type}
      ]
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
    end

    (gen_half.() <> gen_half.())
    |> String.pad_trailing(32, "0")
    |> Base.encode64()
  end
end
