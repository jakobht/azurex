# Integration Tests

To run the integration tests you need to set up Azurite with the default user and keys.
You then need to create two containers in the blob storage:

1. `test`
2. `integrationtestingcontainer`

You then need to create a blob in the `test` container called `test_blob` with the content `test_blob_content`.

You can then run:

```bash
$ mix test --include integration
```

to run all tests including the integration tests.

# Azurite

See how to set up Azurite here:
https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite?tabs=visual-studio

You can then use the Azure Storage Explorer to create the containers and the blob:
https://azure.microsoft.com/en-us/products/storage/storage-explorer/#overview
