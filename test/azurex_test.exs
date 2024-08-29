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
               {"Authorization", _},
               {"x-ms-version", _},
               {"x-ms-date", _},
               {"Content-Type", "application/json"}
             ],
             options: [recv_timeout: 60_000, timeout: 60_000]
           } = request
  end
end
