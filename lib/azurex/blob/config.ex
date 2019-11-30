defmodule Azurex.Blob.Config do
  @moduledoc """
  Azurex Blob Config
  """

  defp conf, do: Application.get_env(:azurex, __MODULE__, [])

  @spec api_url :: String.t()
  def api_url, do: Keyword.get(conf(), :api_url)

  @spec default_container :: String.t() | nil
  def default_container, do: Keyword.get(conf(), :default_container)

  @spec storage_account_name :: String.t()
  def storage_account_name, do: Keyword.get(conf(), :storage_account_name)

  @spec storage_account_key :: nil | binary
  def storage_account_key,
    do: if(key = Keyword.get(conf(), :storage_account_key), do: Base.decode64!(key))

  @spec storage_account_connection_string :: String.t() | nil
  def storage_account_connection_string,
    do: Keyword.get(conf(), :storage_account_connection_string)
end
