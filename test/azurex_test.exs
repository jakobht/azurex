defmodule AzurexTest do
  use ExUnit.Case
  doctest Azurex

  test "ensure HTTPoison Request has correct options, headers and params" do
    Application.put_env(:azurex, Azurex.Blob.Config,
      storage_account_name: "dummystorageaccount",
      storage_account_key:
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
    )

    request =
      Azurex.Blob.blob_request("name", "container", :get,
        recv_timeout: 60_000,
        timeout: 60_000,
        params: [param1: "value1"],
        headers: [{"Content-Type", "application/json"}]
      )

    assert %HTTPoison.Request{
             method: :get,
             url: _,
             params: [param1: "value1"],
             headers: [
               {"Authorization", authz_header},
               {"x-ms-version", _},
               {"x-ms-date", _},
               {"Content-Type", "application/json"}
             ],
             options: [recv_timeout: 60_000, timeout: 60_000]
           } = request

    expected_authz_prefix = "SharedKey dummystorageaccount"

    assert String.starts_with?(authz_header, expected_authz_prefix) == true,
           "expected '#{authz_header}' to have prefix '#{expected_authz_prefix}'"
  end

  test "HTTPoison request uses specified config element for storage account details" do
    Application.put_env(:something_else, Azurex.Blob.Config,
      storage_account_name: "another_account",
      storage_account_key:
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
    )

    request =
      Azurex.Blob.blob_request("name", "container", :get,
        recv_timeout: 60_000,
        timeout: 60_000,
        params: [param1: "value1"],
        headers: [{"Content-Type", "application/json"}],
        config_element: :something_else
      )

    assert %HTTPoison.Request{
             headers: [
               {"Authorization", authz_header},
               {"x-ms-version", _},
               {"x-ms-date", _},
               {"Content-Type", _}
             ]
           } = request

    expected_authz_prefix = "SharedKey another_account"

    assert String.starts_with?(authz_header, expected_authz_prefix) == true,
           "expected '#{authz_header}' to have prefix '#{expected_authz_prefix}'"
  end
end
