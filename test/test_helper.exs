ExUnit.start(exclude: [:integration])

Application.get_env(:ex_unit, :include)
|> Enum.member?(:integration)
|> case do
  true ->
    AzuriteSetup.set_env()
    AzuriteSetup.create_test_containers()
    AzuriteSetup.create_test_blob()

  false ->
    :ok
end
