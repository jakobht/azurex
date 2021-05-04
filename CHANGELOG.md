# Change Log

All notable changes to this project will be documented in this file (at least to the extent possible, I am not infallible sadly).
This project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

### Added/Changed

### Fixed


---

## 0.1.3

### Added/Changed

- Fixed handling of timezone in `x-ms-date` header.

Azure is expecting the `x-ms-date` header to have the trailing timezone code as `GMT`.

`timex` 3.7 requires the timezone code `Etc/GMT` if we want to keep the polarity of the offset the same.

To fix this, have changed the timezone to be `Etc/GMT` and `String.replace` it to `GMT`.

Also, added a test for the above.

### Fixed

- Addressed issues #18
