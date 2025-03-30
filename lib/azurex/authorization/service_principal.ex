defmodule Azurex.Authorization.ServicePrincipal do
  require Logger
  alias Azurex.Blob.Config

  @cache_key "azurex_bearer_token"
  @cache_expiry_margin_seconds 10

  @doc """
  Fetches a bearer token and adds it to the request headers.
  In case fetching the token fails, it logs an error and returns "No token"
  which will fail the real request.
  """
  @spec add_bearer_token(HTTPoison.Request.t(), binary(), binary(), binary()) ::
          HTTPoison.Request.t()
  def add_bearer_token(%HTTPoison.Request{} = request, client_id, client_secret, tenant_id) do
    bearer_token = fetch_bearer_token_cached(client_id, client_secret, tenant_id)
    authorization = {"Authorization", "Bearer #{bearer_token}"}

    headers = [authorization | request.headers]
    struct(request, headers: headers)
  end

  defp fetch_bearer_token_cached(client_id, client_secret, tenant_id) do
    cache_key = @cache_key

    :ets.info(:bearer_token_cache) != :undefined ||
      :ets.new(:bearer_token_cache, [:named_table])

    case :ets.lookup(:bearer_token_cache, cache_key) do
      [{^cache_key, token, expiry}] ->
        if expiry > System.os_time(:second) do
          token
        else
          refresh_bearer_token_cache(client_id, client_secret, tenant_id)
        end

      _ ->
        refresh_bearer_token_cache(client_id, client_secret, tenant_id)
    end
  end

  defp refresh_bearer_token_cache(client_id, client_secret, tenant_id) do
    case fetch_bearer_token(client_id, client_secret, tenant_id) do
      {:ok, token} ->
        expiry = extract_expiry_time(token) - @cache_expiry_margin_seconds
        :ets.insert(:bearer_token_cache, {@cache_key, token, expiry})
        token

      :error ->
        "No token"
    end
  end

  defp extract_expiry_time(token) do
    token
    |> String.split(".")
    |> Enum.at(1)
    |> Base.decode64!()
    |> Jason.decode!()
    |> Map.get("exp")
  end

  defp fetch_bearer_token(client_id, client_secret, tenant_id) do
    body =
      "grant_type=client_credentials&client_id=#{client_id}&client_secret=#{client_secret}&scope=https://storage.azure.com/.default"

    respone =
      %HTTPoison.Request{
        method: :post,
        url: "#{Config.get_auth_url()}/#{tenant_id}/oauth2/v2.0/token",
        body: body,
        headers: [
          {"content-type", "application/x-www-form-urlencoded"}
        ]
      }
      |> HTTPoison.request()

    case respone do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body |> Jason.decode!() |> Map.fetch!("access_token")}

      {:ok, %HTTPoison.Response{status_code: sc, body: body}} ->
        Logger.error("Failed to fetch bearer token. Reason: #{sc}: #{body}")
        :error

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to fetch bearer token. Reason: #{reason}")
        :error
    end
  end
end
