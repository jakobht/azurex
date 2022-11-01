defmodule Azurex.SasIntegrationTests do
  use ExUnit.Case, async: false
  alias Azurex.Blob.SharedAccessSignature

  @moduletag integration: true
  @integration_testing_container "integrationtestingcontainer"

  setup do
    Application.put_env(:azurex, Azurex.Blob.Config,
      storage_account_connection_string:
        "AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;DefaultEndpointsProtocol=http;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1"
    )
  end

  describe "construct sas for test/test_blob" do
    test "sas url works" do
      url = SharedAccessSignature.sas_url("test", "test_blob", resource_type: :blob)

      assert {:ok, %HTTPoison.Response{status_code: 200, body: "test_blob_content"}} =
               HTTPoison.get(url)
    end
  end
end
