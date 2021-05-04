defmodule Azurex.Authorization.SharedKeyTest do
  use ExUnit.Case
  doctest Azurex.Authorization.SharedKey

  alias Azurex.Authorization.SharedKey

  describe("authentication request") do
    test "can format date_time as expected for x-ms-date header" do
      {:ok, time} = Time.new(12, 0, 0, 0)
      {:ok, date} = Date.new(2021, 1, 1)
      {:ok, date_time} = DateTime.new(date, time, "Etc/UTC")
      formatted_time = SharedKey.formatted(date_time)
      assert(formatted_time == "Fri, 01 Jan 2021 12:00:00 GMT")
    end
  end
end
