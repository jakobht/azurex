defmodule Azurex.Authorization.SharedKeyTest do
  use ExUnit.Case
  doctest Azurex.Authorization.SharedKey

  alias Azurex.Authorization.SharedKey

  describe("authentication request") do
    test "can format date_time as expected for x-ms-date header" do
      # We do this for backwards compatibility with Elixir 1.9
      {:ok, naive_date_time} = NaiveDateTime.new(2021, 1, 1, 12, 0, 0)
      {:ok, date_time} = DateTime.from_naive(naive_date_time, "Etc/UTC")
      formatted_time = SharedKey.formatted(date_time)
      assert(formatted_time == "Fri, 01 Jan 2021 12:00:00 GMT")
    end
  end
end
