defmodule AzuriteSetup do
  @moduledoc """
  Test setup helper functions for creating containers and blobs in Azurite in
  support of integration tests.
  """

  @connection_string "AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;DefaultEndpointsProtocol=http;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1"
  @default_container "test"
  @integration_testing_container "integrationtestingcontainer"
  @test_blob_name "test_blob"

  def set_env do
    Application.put_env(:azurex, Azurex.Blob.Config,
      default_container: @default_container,
      storage_account_connection_string: @connection_string
    )
  end

  def create_test_containers do
    Enum.each(
      [
        @default_container,
        @integration_testing_container
      ],
      &create_test_container(&1)
    )
  end

  defp create_test_container(container) do
    container
    |> Azurex.Blob.Container.create()
    |> case do
      {:ok, _} -> :ok
      {:error, :already_exists} -> :ok
      {:error, err} -> raise err
    end
  end

  def create_test_blob do
    Azurex.Blob.put_blob(
      @test_blob_name,
      "test_blob_content",
      "text/plain",
      container: @default_container
    )
  end
end
