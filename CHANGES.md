# Changelog

All notable changes to this project will be documented in this file.

## [0.4.0] - 2024-05-28

### Features

- Upgrade to elixir 16/otp_26

## [0.3.3] - 2023-09-11

### Features

- Add functions to normalize avro messages

## [0.3.2] - 2023-08-22

### Features

- Allow LF terminated avro fragments to be read

### Refactor

- Properly rename the test modules

## [0.3.1] - 2023-02-27

### Bug Fixes

- Make get_raw_values return ok/error tuples

## [0.3.0] - 2023-02-21

### Features

- Make decode/get_raw_value fail if not all data read

### Miscellaneous Tasks

- Bump version to 0.3.0

### Testing

- Use setup blocks and better fun chaining

## [0.2.1] - 2023-02-17

### Features

- Get value functions and encode return tuple

## [0.2.0] - 2023-02-16

### Features

- Bump version and remove unneeded deps
- Review return types for several functions

### Miscellaneous Tasks

- Increase formatter line length to 120
