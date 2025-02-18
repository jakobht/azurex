defmodule Azurex.Authorization.Auth do
  alias Azurex.Blob.Config
  alias Azurex.Authorization.SharedKey
  alias Azurex.Authorization.ServicePrincipal

  @doc """
  Adds authentication header to a given request based on the configured auth method.
  """
  @spec authorize_request(HTTPoison.Request.t(), binary()) :: HTTPoison.Request.t()
  def authorize_request(request, content_type \\ "") do
    case Config.auth_method() do
      {:account_key, storage_account_key} ->
        SharedKey.sign(
          request,
          storage_account_name: Config.storage_account_name(),
          storage_account_key: storage_account_key,
          content_type: content_type
        )

      {:service_principal, client_id, client_secret, tenant} ->
        ServicePrincipal.add_bearer_token(
          request,
          client_id,
          client_secret,
          tenant
        )
        |> SharedKey.put_standard_headers(content_type, DateTime.utc_now())
    end
  end
end
