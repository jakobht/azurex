defmodule Azurex.Authorization.SharedKeyTest do
  use ExUnit.Case
  doctest Azurex.Authorization.SharedKey

  alias Azurex.Authorization.SharedKey

  test "formatted/1 formats datetime  as expected by x-ms-date header" do
    {:ok, time} = Time.new(23, 0, 0, 0)
    {:ok, date} = Date.new(2021, 1, 1)
    {:ok, date_time} = DateTime.new(date, time, "Etc/UTC")
    formatted_time = SharedKey.formatted(date_time)
    assert(formatted_time == "Fri, 01 Jan 2021 23:00:00 GMT")
  end

  test "ss" do
    assert %HTTPoison.Request{
             method: :put,
             url: "https://example.com/sample-path?timeout=1",
             body: "sample body",
             headers: [
               {"x-ms-blob-type", "BlockBlob"}
             ],
             options: [recv_timeout: :infinity]
           }
           |> SharedKey.sign(
             storage_account_name: "dummystorageaccount",
             storage_account_key:
               "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
             content_type: "text/plain"
           ) == %HTTPoison.Request{
             body: "sample body",
             headers: [
               {"authorization",
                "SharedKey dummystorageaccount:hyFKuyt2Go2cKgrBxcEsZTjjIIgP+L3qWlvGP3Wok+o="},
               {"x-ms-version", "2019-12-12"},
               {"x-ms-date", "Fri, 01 Jan 2021 00:00:00 GMT"},
               {"content-type", "text/plain"},
               {"x-ms-blob-type", "BlockBlob"}
             ],
             method: :put,
             options: [recv_timeout: :infinity],
             params: %{},
             url: "https://example.com/sample-path?timeout=1"
           }
  end
end
