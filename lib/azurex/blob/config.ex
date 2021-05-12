defmodule Azurex.Blob.Config do
  @moduledoc """
  Azurex Blob Config
  """

  @missing_envs_error_msg """
  Azurex.Blob.Config: `storage_account_name` and `storage_account_key`
  or `storage_account_connection_string` required.
  """

  defp conf, do: Application.get_env(:azurex, __MODULE__, [])

  @doc """
  Azure endpoint url, optional
  Defaults to `https://{name}.blob.core.windows.net` where `name` is the `storage_account_name`
  """
  @spec api_url :: String.t()
  def api_url do
    case Keyword.get(conf(), :api_url) do
      nil -> "https://#{storage_account_name()}.blob.core.windows.net"
      api_url -> api_url
    end
  end

  @doc """
  Azure container name, optional.
  """
  @spec default_container :: String.t() | nil
  def default_container do
    Keyword.get(conf(), :default_container) ||
      raise "Must specify `container` because the default container was not provided."
  end

  @doc """
  Azure storage account name.
  Required if `storage_account_connection_string` not set.
  """
  @spec storage_account_name :: String.t()
  def storage_account_name do
    case Keyword.get(conf(), :storage_account_name) do
      nil -> get_connection_string_value("AccountName")
      storage_account_name -> storage_account_name
    end || raise @missing_envs_error_msg
  end

  @doc """
  Azure storage account access key. Base64 encoded, as provided by azure UI.
  Required if `storage_account_connection_string` not set.
  """
  @spec storage_account_key :: binary
  def storage_account_key do
    case Keyword.get(conf(), :storage_account_key) do
      nil -> get_connection_string_value("AccountKey")
      key -> key
    end
    |> Kernel.||(raise @missing_envs_error_msg)
    |> Base.decode64!()
  end

  @doc """
  Azure storage account connection string.
  Required if `storage_account_name` or `storage_account_key` not set.
  """
  @spec storage_account_connection_string :: String.t() | nil
  def storage_account_connection_string,
    do: Keyword.get(conf(), :storage_account_connection_string)

  @spec parse_connection_string(nil | binary) :: map
  @doc """
  Parses a connection string to a key value map.

  ## Examples

      iex> parse_connection_string("Key=value")
      %{"Key" => "value"}

      iex> parse_connection_string("Key1=hello;Key2=world")
      %{"Key1" => "hello", "Key2" => "world"}

      iex> parse_connection_string(nil)
      %{}
  """
  def parse_connection_string(nil), do: %{}

  def parse_connection_string(connection_string) do
    connection_string
    |> String.split(";")
    |> Enum.map(&String.split(&1, "=", parts: 2))
    |> Map.new(fn [key, value] -> {key, value} end)
  end

  @doc """
  Returns the value in the connection string given the string key.
  """
  @spec get_connection_string_value(String.t()) :: String.t() | nil
  def get_connection_string_value(key) do
    storage_account_connection_string()
    |> parse_connection_string
    |> Map.get(key)
  end
end
