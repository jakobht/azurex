defmodule Azurex.ContainerIntegrationTests do
  use ExUnit.Case, async: false
  alias Azurex.Blob.Container

  @moduletag integration: true
  @integration_testing_container "integrationtestingcontainer"

  setup do
    Application.put_env(:azurex, Azurex.Blob.Config,
      storage_account_connection_string:
        "AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;DefaultEndpointsProtocol=http;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1"
    )
  end

  describe "head container" do
    test "returns ok when the container exists" do
      assert {:ok, _} = Container.head_container(@integration_testing_container)
    end

    test "returns not_found when the container does not exist" do
      assert {:error, :not_found} = Container.head_container("thiscontainershouldnotexist")
    end

    test "returns an error when the container name is invalid" do
      assert {:error, %HTTPoison.Response{status_code: 400}} =
               Container.head_container("Thi$isinvalid")
    end
  end
end
