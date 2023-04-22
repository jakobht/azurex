import Config

config :azurex, Azurex.Blob.Config,
  api_url: "http://{name}.blob.core.windows.net",
  default_container: "default container",
  storage_account_name: "name",
  storage_account_key: "base64 encoded key",
  storage_account_connection_string: "connection string"

# DO NOT USE BOTH STYLES OF CONFIGURATION
# IF ABOVE CONFIG IS USED THEN ALL BELOW CONFIGS WILL BE IGNORED
config :my_app, :azurex,
  api_url: "http://my_app.blob.core.windows.net",
  default_container: "default container for my_app",
  storage_account_name: "my_app_account_name",
  storage_account_key: "my_app_account_key,
  storage_account_connection_string: "my_app connection string"

config :my_app_two, :azurex,
  api_url: "http://my_app_two.blob.core.windows.net",
  default_container: "default container for my_app_two",
  storage_account_name: "my_app_two_account_name",
  storage_account_key: "my_app_two_account_key,
  storage_account_connection_string: "my_app_two connection string"