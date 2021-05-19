import Config

# Used when running integration tests
# Connects to the default Azurite server. The Azurite server should have two containers already made:
# `test` and `integrationtestingcontainer`
config :azurex, Azurex.Blob.Config,
  default_container: "test",
  storage_account_connection_string:
    "AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;DefaultEndpointsProtocol=http;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1"
