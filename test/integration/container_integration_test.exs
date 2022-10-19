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

  describe "create container" do
    test "creates a new container" do
      container_name = for _ <- 1..32, into: "", do: <<Enum.random('abcdefghijklmnopqrstuvwxyz')>>

      assert {:error, :not_found} = Container.head_container(container_name)
      assert {:ok, ^container_name} = Container.create(container_name)
      assert {:ok, _} = Container.head_container(container_name)
    end

    test "returns an error if the container already exists" do
      assert {:error, :already_exists} = Container.create(@integration_testing_container)
    end

    test "returns an error if the container name is invalid" do
      assert {:error, %HTTPoison.Response{status_code: 400}} = Container.create("@$1")
    end
  end
end
