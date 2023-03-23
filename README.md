[![Elixir CI](https://github.com/jakobht/azurex/actions/workflows/elixir.yml/badge.svg)](https://github.com/jakobht/azurex/actions/workflows/elixir.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/azurex)](https://hex.pm/packages/azurex)

# Azurex

Implementation of the Azure Blob Storage [Rest API](https://docs.microsoft.com/en-us/rest/api/storageservices/blob-service-rest-api) for Elixir.

## Supported actions

Currently supports:

1. Downloading blobs
2. Uploading blobs

## Installation

[Available in Hex](https://hex.pm/packages/azurex), the package can be installed
by adding `azurex` to your list of dependencies in `mix.exs` e.g.:

```elixir
def deps do
  [
    {:azurex, "~> 1.0.0"}
  ]
end
```

## Configuration

The configuration should _either_ define `storage_account_name` and `storage_account_key` _or_ `storage_account_connection_string`.

There are two ways to define the configuration:

### Module Configuration

```elixir
config :azurex, Azurex.Blob.Config,
  api_url: "https://sample.blob.core.windows.net", # Optional
  default_container: "defaultcontainer", # Optional
  storage_account_name: "name",
  storage_account_key: "access key",
  storage_account_connection_string: "Storage=Account;Connection=String" # Required if storage account `name` and `key` not set
```

### Application Specific Configuration (Umbrella Project)

```elixir
config :my_app, :azurex,
  ....
```

## Documentation

Documentation can be found at [https://hexdocs.pm/azurex](https://hexdocs.pm/azurex). Or generated using [ExDoc](https://github.com/elixir-lang/ex_doc)

## Development

The goal is to support all actions in the Azure Blob Storage [Rest API](https://docs.microsoft.com/en-us/rest/api/storageservices/blob-service-rest-api) - PRs welcome :)
