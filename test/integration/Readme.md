# Integration Tests

To run the integration tests you need to set up Azurite with the default user and keys.

You can then run:

```bash
$ mix test --include integration
```

to run all tests including the integration tests.

The integration test setup will attempt to create two containers in the blob storage:

1. `test`
2. `integrationtestingcontainer`

The setup will also attempt to create a blob in the `test` container called `test_blob` with the content `test_blob_content`.

These setup steps rely on lib code to create these objects. If this behavior has broken, you can use the Azure Storage Explorer to create the containers and the blob:
https://azure.microsoft.com/en-us/products/storage/storage-explorer/#overview

# Azurite

See how to set up Azurite here:
https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite?tabs=visual-studio
