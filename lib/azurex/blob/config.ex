defmodule Azurex.Blob.Config do
  @moduledoc """
  Azurex Blob Config
  """

  @missing_envs_error_msg """
  Azurex.Blob.Config: `storage_account_name` and `storage_account_key`
  or `storage_account_connection_string` required.
  """

  defp conf, do: Application.get_env(:azurex, __MODULE__, [])

  @spec api_url(atom) :: <<_::64, _::_*8>>
  @doc """
  Azure endpoint url, optional
  Defaults to `https://{name}.blob.core.windows.net` where `name` is the `storage_account_name`
  """

  def api_url(enviroment_name) do
    "https://#{storage_account_name(enviroment_name)}.blob.core.windows.net"
  end

  @spec storage_account_name(atom) :: any
  @doc """
  Azure storage account name.
  Required if `storage_account_connection_string` not set.
  """

  def storage_account_name(enviroment_name) do
    case Keyword.get(conf(), enviroment_name) do
      nil -> raise @missing_envs_error_msg
      connection_string -> get_connection_string_value(connection_string, "AccountName")
    end
  end

  @spec storage_account_key(atom) :: binary
  @doc """
  Azure storage account access key. Base64 encoded, as provided by azure UI.
  Required if `storage_account_connection_string` not set.
  """

  def storage_account_key(enviroment_name) do
    case Keyword.get(conf(), enviroment_name) do
      nil -> raise @missing_envs_error_msg
      connection_string -> get_connection_string_value(connection_string, "AccountKey")
    end
    |> Base.decode64!()
  end

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

  def get_connection_string_value(connection_string, key) do
    connection_string
    |> parse_connection_string
    |> Map.get(key)
  end
end
