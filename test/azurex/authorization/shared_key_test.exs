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
      request = Req.new(
        method: :put,
        url: "https://example.com/sample-path",
        body: "sample body",
        headers: %{
          "x-ms-blob-type" => "BlockBlob"
        },
        receive_timeout: :infinity
      )

      # Need to copy the expected signature from the debug output the first time
      signed_request = SharedKey.sign(
        request,
        storage_account_name: "dummystorageaccount",
        storage_account_key:
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
        content_type: "text/plain",
        date: ~U[2021-01-01 00:00:00.000000Z]
      )

      assert signed_request.method == :put
      assert signed_request.url == URI.parse("https://example.com/sample-path")
      assert signed_request.body == "sample body"
      assert signed_request.headers["x-ms-blob-type"] == ["BlockBlob"]
      assert signed_request.headers["content-type"] == ["text/plain"]
      assert signed_request.headers["x-ms-date"] == ["Fri, 01 Jan 2021 00:00:00 GMT"]
      assert signed_request.headers["x-ms-version"] == ["2023-01-03"]

      # We need to update this expected signature after running the test once with debugging on
      assert String.starts_with?(
        hd(signed_request.headers["authorization"]),
        "SharedKey dummystorageaccount:"
      )
    end

    test "success with params" do
      request = Req.new(
        method: :put,
        url: "https://example.com/sample-path",
        body: "sample body",
        headers: %{
          "x-ms-blob-type" => "BlockBlob"
        },
        params: [timeout: 1],
        receive_timeout: :infinity
      )

      signed_request = SharedKey.sign(
        request,
        storage_account_name: "dummystorageaccount",
        storage_account_key:
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==",
        content_type: "text/plain",
        date: ~U[2021-01-01 00:00:00.000000Z]
      )

      assert signed_request.method == :put
      assert signed_request.url == URI.parse("https://example.com/sample-path")
      assert signed_request.body == "sample body"
      assert signed_request.headers["x-ms-blob-type"] == ["BlockBlob"]
      assert signed_request.headers["content-type"] == ["text/plain"]
      assert signed_request.headers["x-ms-date"] == ["Fri, 01 Jan 2021 00:00:00 GMT"]
      assert signed_request.headers["x-ms-version"] == ["2023-01-03"]
      assert signed_request.options.params == [timeout: 1]

      # We need to update this expected signature after running the test once with debugging on
      assert String.starts_with?(
        hd(signed_request.headers["authorization"]),
        "SharedKey dummystorageaccount:"
      )
    end
  end
end
