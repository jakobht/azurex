defmodule Azurex.Authorization.SharedKeyTest do
  use ExUnit.Case
  doctest Azurex.Authorization.SharedKey

  alias Azurex.Authorization.SharedKey

  describe("authentication request") do
    test "can format date_time as expected for x-ms-date header" do
      # We do this for backwards compatibility with Elixir 1.9
      {:ok, naive_date_time} = NaiveDateTime.new(2021, 1, 1, 12, 0, 0)
      {:ok, date_time} = DateTime.from_naive(naive_date_time, "Etc/UTC")

      assert SharedKey.format_date(date_time) == "Fri, 01 Jan 2021 12:00:00 GMT"
    end
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

    test "success with params for stream request body" do
      stream = Stream.cycle("sample body")

      request = %HTTPoison.Request{
        method: :put,
        url: "https://example.com/sample-path",
        body: {:stream, stream},
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
               body: {:stream, stream},
               headers: [
                 {"authorization",
                  "SharedKey dummystorageaccount:j9iXJN9L6fiBfl1v0Pa94gX8vFvp6S4ln9qxWoKAgAs="},
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
