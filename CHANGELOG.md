# Change Log

All notable changes to this project will be documented in this file (at least to the extent possible, I am not infallible sadly).
This project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

### Added/Changed

### Fixed

---

## 1.0.0

- Bump to version 1.0.0, has been used in production in several places

### Added/Changed

- Added support generating SAS urls to allow for limited access to the blob storage (PR #30, thanks @cblavier)
- Added support for HEAD blob requests, to check if a blob exists without downloading the full blob (PR #31, thanks @ShahneRodgers)
- Added better integration testing.
- Updated dependencies

### Fixed

## 0.1.5

### Added/Changed

### Fixed

- Updated the `Azurex.Blob.list_containers` to use HTTPoison params instead of hard coding it in the URL. Hard coding in the URL breaks in Elixir 1.12.

## 0.1.4

### Added/Changed

- Changed config behaviour, now only `storage_account_name` and `storage_account_key` or `storage_account_connection_string` required. Refer to the `Azurex.Blob.Config` documentation.
- Internal code refactor, including better tests and documentation;

### Fixed

- Fixed handling of multiple query parameters;
- Fixed config `storage_account_connection_string` not doing anything.

### Potential Breaking

- Renamed `Azurex.Blob.get_blob_url(name, container \\ nil)` to `Azurex.Blob.get_url(container, name)`

## 0.1.3

### Added/Changed

- Fixed handling of timezone in `x-ms-date` header.

Azure is expecting the `x-ms-date` header to have the trailing timezone code as `GMT`.

Migrated to strftime in `timex` when elixir 1.11 is more acessible in different repos we will migrate to the Elixir DateTime and Calendar tools and remove `timex` dependency.

Also, added a test for the above.

### Fixed

- Addressed issues #18
