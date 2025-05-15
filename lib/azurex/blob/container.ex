defmodule Azurex.Blob.Container do
  @moduledoc """
  Implementation of Azure Blob Storage
  """
  alias Azurex.Authorization.Auth
  alias Azurex.Blob.Config

  def head_container(container, overrides \\ []) do
    connection_params = Config.get_connection_params(overrides)

    %HTTPoison.Request{
      url: Config.api_url(connection_params) <> "/" <> container,
      params: [restype: "container"],
      method: :head
    }
    |> Auth.authorize_request(connection_params)
    |> HTTPoison.request()
    |> case do
      {:ok, %{status_code: 200, headers: headers}} -> {:ok, headers}
      {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, :not_found}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  def create(container, overrides \\ []) do
    connection_params = Config.get_connection_params(overrides)

    %HTTPoison.Request{
      url: Config.api_url(connection_params) <> "/" <> container,
      params: [restype: "container"],
      method: :put
    }
    |> Auth.authorize_request(connection_params, "application/octet-stream")
    |> HTTPoison.request()
    |> case do
      {:ok, %{status_code: 201}} -> {:ok, container}
      {:ok, %HTTPoison.Response{status_code: 409}} -> {:error, :already_exists}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end
end
