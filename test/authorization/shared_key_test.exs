defmodule Azurex.Authorization.SharedKeyTest do
  use ExUnit.Case
  doctest Azurex.Authorization.SharedKey

  alias Azurex.Authorization.SharedKey

  test "formatted/1 formats datetime  as expected by x-ms-date header" do
    {:ok, time} = Time.new(23, 0, 0, 0)
    {:ok, date} = Date.new(2021, 1, 1)
    {:ok, date_time} = DateTime.new(date, time, "Etc/UTC")

    assert SharedKey.format_date(date_time) == "Fri, 01 Jan 2021 23:00:00 GMT"
  end

  describe "sign/2" do
    test "success without params" do
      request = %HTTPoison.Request{
        method: :put,
        url: "https://example.com/sample-path",
        body: "sample body",
        headers: [
          {"x-ms-blob-type", "BlockBlob"}
        ],
        options: [recv_timeout: :infinity]
      }

      assert SharedKey.sign(
               request,
               storage_account_name: "dummystorageaccount",
               storage_account_key:
                 "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
               content_type: "text/plain",
               date: ~U[2021-01-01 00:00:00.000000Z]
             ) == %HTTPoison.Request{
               body: "sample body",
               headers: [
                 {"authorization",
                  "SharedKey dummystorageaccount:D9brdlYGXAlZ8+2DtdcrHxQTILPKGjFigA3gMySE8r0="},
                 {"x-ms-version", "2019-12-12"},
                 {"x-ms-date", "Fri, 01 Jan 2021 00:00:00 GMT"},
                 {"content-type", "text/plain"},
                 {"x-ms-blob-type", "BlockBlob"}
               ],
               method: :put,
               options: [recv_timeout: :infinity],
               url: "https://example.com/sample-path"
             }
    end

    test "success with params" do
      request = %HTTPoison.Request{
        method: :put,
        url: "https://example.com/sample-path",
        body: "sample body",
        headers: [
          {"x-ms-blob-type", "BlockBlob"}
        ],
        params: [timeout: 1],
        options: [recv_timeout: :infinity]
      }

      assert SharedKey.sign(
               request,
               storage_account_name: "dummystorageaccount",
               storage_account_key:
                 "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
               content_type: "text/plain",
               date: ~U[2021-01-01 00:00:00.000000Z]
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
               params: [timeout: 1],
               url: "https://example.com/sample-path"
             }
    end
  end
end
