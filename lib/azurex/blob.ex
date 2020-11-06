defmodule Azurex.Blob do
  alias Azurex.Blob.Config
  alias Azurex.Authorization.SharedKey

  def list_containers do
    %HTTPoison.Request{
      url: Config.api_url() <> "?comp=list"
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key()
    )
    |> HTTPoison.request()
  end

  @spec put_blob(String.t(), binary, String.t(), keyword) ::
          :ok
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def put_blob(name, blob, content_type, opts \\ []) do
    query =
      if timeout = Keyword.get(opts, :timeout),
        do: "?" <> URI.encode_query([{"timeout", timeout}]),
        else: ""

    %HTTPoison.Request{
      method: :put,
      url: "#{Config.api_url()}/#{Config.default_container()}/#{name}#{query}",
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

  @spec get_blob(String.t()) ::
          {:ok, binary()}
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def get_blob(name) do
    %HTTPoison.Request{
      method: :get,
      url: get_blob_url(name)
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key()
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{body: blob, status_code: 200}} -> {:ok, blob}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  def get_blob_url(name) do
    "#{Config.api_url()}/#{Config.default_container()}/#{name}"
  end
end
