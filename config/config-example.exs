import Config

config :azurex, Azurex.Blob.Config,
  api_url: "http://{name}.blob.core.windows.net",
  default_container: "default container",
  storage_account_name: "name",
  storage_account_key: "base64 encoded key",
  storage_account_connection_string: "connection string"
