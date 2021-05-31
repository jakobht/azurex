import Config

config :azurex, Azurex.Blob.Config,
  enviroments: [
    default: "connection string"
    secondary: "other connection string"
  ]
