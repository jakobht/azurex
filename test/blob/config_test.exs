defmodule Azurex.Blob.ConfigTest do
  use ExUnit.Case, async: false
  import Azurex.Blob.Config

  doctest Azurex.Blob.Config

  @sample_connection_string "DefaultEndpointsProtocol=https;AccountKey=Y3Nfc2FtcGxlX2tleQ==;AccountName=cs_samplename"

  setup do
    Application.put_env(:azurex, Azurex.Blob.Config,
      storage_account_connection_string:
        "AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;DefaultEndpointsProtocol=http;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1"
    )

    # original_conf = Application.get_env(:azurex, Azurex.Blob.Config)
    # on_exit(fn -> Application.put_env(:azurex, Azurex.Blob.Config, original_conf) end)
  end

  defp put_config(config \\ []) do
    Application.put_env(:azurex, Azurex.Blob.Config, config)
  end

  describe "storage_account_name/0" do
    test "returns configured env" do
      put_config(storage_account_name: "samplename")

      assert storage_account_name() == "samplename"
    end

    test "returns based on storage_account_connection_string env" do
      put_config(storage_account_connection_string: @sample_connection_string)
      assert storage_account_name() == "cs_samplename"
    end

    test "error no env set" do
      put_config()
      assert_raise RuntimeError, &storage_account_name/0
    end
  end

  describe "storage_account_key/0" do
    test "returns configured env" do
      put_config(storage_account_key: Base.encode64("sample key"))

      assert storage_account_key() == "sample key"
    end

    test "returns based on storage_account_connection_string env" do
      put_config(storage_account_connection_string: @sample_connection_string)
      assert storage_account_key() == "cs_sample_key"
    end

    test "error no env set" do
      put_config()
      assert_raise RuntimeError, &storage_account_key/0
    end
  end

  describe "default_container/0" do
    test "returns configured env" do
      Application.put_env(:azurex, Azurex.Blob.Config, default_container: "sample_container_name")
      assert default_container() == "sample_container_name"
    end

    test "env not set" do
      put_config()
      assert_raise RuntimeError, &default_container/0
    end
  end

  describe "api_url/0" do
    test "returns api_url from config" do
      assert api_url() == "http://127.0.0.1:10000/devstoreaccount1"
    end

    test "returns configured env" do
      put_config(api_url: "https://example.com")

      assert api_url() == "https://example.com"
    end

    test "returns url based on storage_account_name env" do
      put_config(storage_account_name: "sample-name")
      assert api_url() == "https://sample-name.blob.core.windows.net"
    end

    test "returns url based on storage_account_connection_string env" do
      put_config(storage_account_connection_string: @sample_connection_string)
      assert api_url() == "https://cs_samplename.blob.core.windows.net"
    end

    test "returns url based on BlobEndPoint in storage_account_connection_string env" do
      connection_string =
        @sample_connection_string <> ";BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1"

      put_config(storage_account_connection_string: connection_string)
      assert api_url() == "http://127.0.0.1:10000/devstoreaccount1"
    end

    test "error no env set" do
      put_config()
      assert_raise RuntimeError, &api_url/0
    end
  end

  describe "get_connection_string_value/1" do
    test "success" do
      put_config(storage_account_connection_string: "Key=value")

      assert get_connection_string_value("Key") == "value"
    end

    test "env not in connection_string" do
      put_config(storage_account_connection_string: "Key=value")

      assert get_connection_string_value("Invalid") == nil
    end

    test "connection_string env not set" do
      put_config()

      assert get_connection_string_value("Invalid") == nil
    end
  end
end
