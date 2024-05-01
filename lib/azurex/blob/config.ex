defmodule Azurex.Blob.Config do
  @moduledoc """
  Azurex Blob Config
  """

  @type config_overrides :: String.t() | keyword

  @missing_envs_error_msg """
  Azurex.Blob.Config: `storage_account_name` and `storage_account_key`
  or `storage_account_connection_string` required.
  """

  defp conf, do: Application.get_env(:azurex, __MODULE__, [])

  @doc """
  Azure endpoint url, optional
  Defaults to `https://{name}.blob.core.windows.net` where `name` is the `storage_account_name`
  """
  @spec api_url(keyword) :: String.t()
  def api_url(connection_params \\ []) do
    Keyword.get(connection_params, :api_url) ||
      get_connection_string_from_params("BlobEndpoint", connection_params) ||
      Keyword.get(conf(), :api_url) ||
      get_connection_string_value("BlobEndpoint") ||
      "https://#{storage_account_name(connection_params)}.blob.core.windows.net"
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
  @spec storage_account_name(keyword) :: String.t()
  def storage_account_name(connection_params \\ []) do
    Keyword.get(connection_params, :storage_account_name) ||
      get_connection_string_from_params("AccountName", connection_params) ||
      Keyword.get(conf(), :storage_account_name) ||
      get_connection_string_value("AccountName") ||
      raise @missing_envs_error_msg
  end

  @doc """
  Azure storage account access key. Base64 encoded, as provided by azure UI.
  Required if `storage_account_connection_string` not set.
  """
  @spec storage_account_key(keyword) :: binary
  def storage_account_key(connection_params \\ []) do
    encoded_account_key =
      Keyword.get(connection_params, :storage_account_key) ||
        get_connection_string_from_params("AccountKey", connection_params) ||
        Keyword.get(conf(), :storage_account_key) ||
        get_connection_string_value("AccountKey") ||
        raise @missing_envs_error_msg

    Base.decode64!(encoded_account_key)
  end

  @doc """
  Azure storage account connection string.
  Required if `storage_account_name` or `storage_account_key` not set.
  """
  @spec storage_account_connection_string(keyword) :: String.t() | nil
  def storage_account_connection_string(connection_params \\ []) do
    Keyword.get(connection_params, :storage_account_connection_string) ||
      Keyword.get(conf(), :storage_account_connection_string)
  end

  @spec parse_connection_string(nil | binary) :: map
  @doc """
  Parses a connection string to a key value map.

  ## Examples

      iex> parse_connection_string("Key=value")
      %{"Key" => "value"}

      iex> parse_connection_string("Key=value;")
      %{"Key" => "value"}

      iex> parse_connection_string("Key1=hello;Key2=world")
      %{"Key1" => "hello", "Key2" => "world"}

      iex> parse_connection_string(nil)
      %{}
  """
  def parse_connection_string(nil), do: %{}

  def parse_connection_string(connection_string) do
    connection_string
    |> String.split(";", trim: true)
    |> Enum.map(&String.split(&1, "=", parts: 2))
    |> Map.new(fn [key, value] -> {key, value} end)
  end

  @doc """
  Returns the value in the connection string given the string key.
  """
  @spec get_connection_string_value(String.t(), config_overrides) :: String.t() | nil
  def get_connection_string_value(key, connection_params \\ []) do
    storage_account_connection_string(connection_params)
    |> parse_connection_string()
    |> Map.get(key)
  end

  @doc """
  Returns the given configuration keyword list.
  If the parameter is a string, it is interpreted as the container for backwards compatibility.
  """
  @spec get_connection_params(config_overrides | nil) :: keyword()
  def get_connection_params(nil), do: []
  def get_connection_params(container) when is_binary(container), do: [container: container]
  def get_connection_params(config), do: config

  @spec get_connection_string_from_params(String.t(), config_overrides) :: String.t() | nil
  defp get_connection_string_from_params(key, connection_params) do
    # Needed to prioritize keys from parameters
    Keyword.get(connection_params, :storage_account_connection_string)
    |> parse_connection_string()
    |> Map.get(key)
  end
end
