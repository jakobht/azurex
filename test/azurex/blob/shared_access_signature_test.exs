defmodule Azurex.Blob.SharedAccessSignatureTest do
  use ExUnit.Case
  import Azurex.Blob.SharedAccessSignature

  setup_all do
    Application.put_env(:azurex, Azurex.Blob.Config,
      storage_account_name: "storage_account",
      storage_account_key: Base.encode64("secretkey")
    )
  end

  test "sas container url" do
    assert sas_url(container(), "/", from: now()) ==
             "https://storage_account.blob.core.windows.net/my_container?sv=2020-12-06&st=2022-10-10T10%3A10%3A00Z&se=2022-10-10T11%3A10%3A00Z&sr=c&sp=r&sig=NRjiSKbIhZPcu99pYt2bS015eQOMTX8WVIh3hJdj%2Fwk%3D"
  end

  test "sas blob url" do
    assert sas_url(container(), blob(),
             from: now(),
             expiry: {:second, 2 * 24 * 3600},
             permissions: [:read, :write]
           ) ==
             "https://storage_account.blob.core.windows.net/my_container/folder/blob.mp4?sv=2020-12-06&st=2022-10-10T10%3A10%3A00Z&se=2022-10-12T10%3A10%3A00Z&sr=c&sp=rw&sig=Y2vH1nKzPkQhMnEXzz1m9Bz3o%2FPhyS1nOQp91B5GK9k%3D"
  end

  test "permissions order does not matter" do
    assert sas_url(container(), blob(), from: now(), permissions: [:read, :add, :write, :delete]) ==
             sas_url(container(), blob(), from: now(), permissions: [:delete, :write, :add, :read])
  end

  defp container, do: "my_container"
  defp blob, do: "/folder/blob.mp4"
  defp now, do: ~U[2022-10-10 10:10:00Z]
end
