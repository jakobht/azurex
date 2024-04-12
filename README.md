[![Elixir CI](https://github.com/jakobht/azurex/actions/workflows/elixir.yml/badge.svg)](https://github.com/jakobht/azurex/actions/workflows/elixir.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/azurex)](https://hex.pm/packages/azurex)

# Azurex

Implementation of the Azure Blob Storage [Rest API](https://docs.microsoft.com/en-us/rest/api/storageservices/blob-service-rest-api) for Elixir.

## Supported actions

Currently supports:

1. Downloading blobs
2. Uploading blobs
3. Deleting blobs
4. Stream uploading blobs
5. Listing blobs
6. Creating containers
7. Listing containers

## Installation

[Available in Hex](https://hex.pm/packages/azurex), the package can be installed
by adding `azurex` to your list of dependencies in `mix.exs` e.g.:

```elixir
def deps do
  [
    {:azurex, "~> 1.1.0"}
  ]
end
```

## Configuration

The configuration should _either_ define `storage_account_name` and `storage_account_key` _or_ `storage_account_connection_string`.

```elixir
config :azurex, Azurex.Blob.Config,
  api_url: "https://sample.blob.core.windows.net", # Optional
  default_container: "defaultcontainer", # Optional
  storage_account_name: "name",
  storage_account_key: "access key",
  storage_account_connection_string: "Storage=Account;Connection=String" # Required if storage account `name` and `key` not set
```

Each of these options is then overridable per-request, if you need to work with multiple instances:

```elixir
Azurex.Blob.list_blobs(container: "other", api_uri: "https://other.blob.net")

Azurex.Blob.get_blob("file.txt", [
  storage_account_connection_string: "Account=Storage;String=Connection"
])

Azurex.Blob.put_blob("file.txt", "contents", "text/plain", [
  storage_account_key: "key",
  storage_account_name: "name"
])
```

## Documentation

Documentation can be found at [https://hexdocs.pm/azurex](https://hexdocs.pm/azurex). Or generated using [ExDoc](https://github.com/elixir-lang/ex_doc)

## Development

The goal is to support all actions in the Azure Blob Storage [Rest API](https://docs.microsoft.com/en-us/rest/api/storageservices/blob-service-rest-api) - PRs welcome :)
