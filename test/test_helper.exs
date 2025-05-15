ExUnit.start(exclude: [:integration, :azure_integration])

included = Application.get_env(:ex_unit, :include)
is_azure_integration = Enum.member?(included, :azure_integration)
is_integration = Enum.member?(included, :integration)

case {is_integration, is_azure_integration} do
  {false, false} ->
    :ok

  {true, false} ->
    AzuriteSetup.set_env()
    AzuriteSetup.create_test_containers()
    AzuriteSetup.create_test_blob()

  {false, true} ->
    AzureSetup.set_env()
    AzureSetup.create_test_containers()
    AzureSetup.create_test_blob()

  _ ->
    raise "Cannot run both integration and azure_integration tests at the same time"
end
