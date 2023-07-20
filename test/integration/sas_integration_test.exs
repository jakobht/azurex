defmodule Azurex.SasIntegrationTests do
  use ExUnit.Case, async: false
  alias Azurex.Blob.SharedAccessSignature

  @moduletag integration: true

  setup do
    # set integration test env in case another test has overwritten it
    AzuriteSetup.set_env()
  end

  describe "construct sas for test/test_blob" do
    test "sas url works" do
      url = SharedAccessSignature.sas_url("test", "test_blob", resource_type: :blob)

      assert {:ok, %HTTPoison.Response{status_code: 200, body: "test_blob_content"}} =
               HTTPoison.get(url)
    end
  end
end
