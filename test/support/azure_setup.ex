defmodule AzureSetup do
  @moduledoc """
  Test setup helper functions for creating containers and blobs in Azurite in
  support of integration tests.
  """

  @default_container "test"
  @integration_testing_container "integrationtestingcontainer"
  @test_blob_name "test_blob"

  def set_env do
    Application.put_env(:azurex, Azurex.Blob.Config,
      storage_account_name: System.get_env("STORAGE_ACCOUNT_NAME"),
      default_container: @default_container,
      storage_client_id: System.get_env("STORAGE_CLIENT_ID"),
      storage_client_secret: System.get_env("STORAGE_CLIENT_SECRET"),
      storage_tenant_id: System.get_env("STORAGE_TENANT_ID")
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
      @default_container
    )
  end
end
