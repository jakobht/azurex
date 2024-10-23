defmodule Azurex.Blob.Config do
  @moduledoc """
  Azurex Blob Config
  """

  @missing_envs_error_msg """
  Azurex.Blob.Config: `storage_account_name` and `storage_account_key`
  or `storage_account_connection_string` required.
  """

  defp conf(config_element), do: Application.get_env(config_element, __MODULE__, [])

  @doc """
  Azure endpoint url, optional
  Defaults to `https://{name}.blob.core.windows.net` where `name` is the `storage_account_name`
  """
  @spec api_url(atom()) :: String.t()
  # TODO this, and below functions are public therefore we should probably default this
  def api_url(config_element) do
    cond do
      api_url = Keyword.get(conf(config_element), :api_url) -> api_url
      api_url = get_connection_string_value("BlobEndpoint", config_element) -> api_url
      true -> "https://#{storage_account_name(config_element)}.blob.core.windows.net"
    end
  end

  @doc """
  Azure container name, optional.
  """
  @spec default_container(atom()) :: String.t() | nil
  def default_container(config_element) do
    Keyword.get(conf(config_element), :default_container) ||
      raise "Must specify `container` because the default container was not provided."
  end

  @doc """
  Azure storage account name.
  Required if `storage_account_connection_string` not set.
  """
  @spec storage_account_name(atom()) :: String.t()
  def storage_account_name(config_element) do
    case Keyword.get(conf(config_element), :storage_account_name) do
      nil -> get_connection_string_value("AccountName", config_element)
      storage_account_name -> storage_account_name
    end || raise @missing_envs_error_msg
  end

  @doc """
  Azure storage account access key. Base64 encoded, as provided by azure UI.
  Required if `storage_account_connection_string` not set.
  """
  @spec storage_account_key(atom()) :: binary
  def storage_account_key(config_element) do
    case Keyword.get(conf(config_element), :storage_account_key) do
      nil -> get_connection_string_value("AccountKey", config_element)
      key -> key
    end
    |> Kernel.||(raise @missing_envs_error_msg)
    |> Base.decode64!()
  end

  @doc """
  Azure storage account connection string.
  Required if `storage_account_name` or `storage_account_key` not set.
  """
  @spec storage_account_connection_string(atom()) :: String.t() | nil
  def storage_account_connection_string(config_element),
    do: Keyword.get(conf(config_element), :storage_account_connection_string)

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
  @spec get_connection_string_value(String.t(), atom()) :: String.t() | nil
  def get_connection_string_value(key, config_element) do
    storage_account_connection_string(config_element)
    |> parse_connection_string
    |> Map.get(key)
  end
end
