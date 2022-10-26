defmodule Azurex.ContainerIntegrationTests do
  use ExUnit.Case, async: false
  alias Azurex.Blob.Container

  @moduletag integration: true
  @integration_testing_container "integrationtestingcontainer"

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
