defmodule Azurex.BobIntegrationTests do
  use ExUnit.Case, async: false
  alias Azurex.Blob

  @moduletag integration: true

  @sample_file_contents "sample file\ncontents\n"
  @integration_testing_container "integrationtestingcontainer"

  describe "upload and download a blob" do
    test "using default container" do
      blob_name = make_blob_name()

      assert Blob.put_blob(
               blob_name,
               @sample_file_contents,
               "text/plain"
             ) == :ok

      assert Blob.get_blob(blob_name) == {:ok, @sample_file_contents}
    end

    test "passing container" do
      blob_name = make_blob_name()

      assert Blob.put_blob(
               blob_name,
               @sample_file_contents,
               "text/plain",
               @integration_testing_container
             ) == :ok

      assert Blob.get_blob(
               blob_name,
               @integration_testing_container
             ) == {:ok, @sample_file_contents}
    end

    test "passing container and params" do
      blob_name = make_blob_name()

      assert Blob.put_blob(
               blob_name,
               @sample_file_contents,
               "text/plain",
               @integration_testing_container,
               timeout: 10,
               ignored_param: "ignored_param_value"
             ) == :ok

      assert Blob.get_blob(
               blob_name,
               @integration_testing_container,
               timeout: 10
             ) == {:ok, @sample_file_contents}
    end
  end

  describe "list blobs" do
    test "simple, not checking result" do
      assert {:ok, _result_not_checked} = Blob.list_blobs()
    end

    test "passing container, not checking result" do
      assert {:ok, _result_not_checked} = Blob.list_blobs(@integration_testing_container)
    end

    test "passing container and params, not checking result" do
      assert {:ok, _result_not_checked} =
               Blob.list_blobs(@integration_testing_container, timeout: 10)
    end
  end

  describe "test containers" do
    test "list containers" do
      assert {:ok, _results} = Blob.list_containers()
    end
  end

  defp make_blob_name do
    escaped_time =
      DateTime.utc_now()
      |> DateTime.to_iso8601()
      |> String.replace(":", ".")

    "#{escaped_time}.txt"
  end
end
