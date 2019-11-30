defmodule Azurex.Blob.Config do
  @moduledoc """
  Azurex Blob Config
  """

  defp conf, do: Application.get_env(:azurex, __MODULE__, [])

  def api_url, do: Keyword.get(conf(), :api_url)

  def default_container, do: Keyword.get(conf(), :default_container)
  def storage_account_name, do: Keyword.get(conf(), :storage_account_name)

  def storage_account_key,
    do: if(key = Keyword.get(conf(), :storage_account_key), do: Base.decode64!(key))

  def storage_account_connection_string,
    do: Keyword.get(conf(), :storage_account_connection_string)
end
