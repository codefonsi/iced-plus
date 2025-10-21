# KeyPath Test Example

This example demonstrates the integration of `key-paths-core` and `key-paths-derive` with Iced.

## Purpose

- Test the `#[derive(KeyPaths)]` macro on nested app state structures
- Prepare structure for using key paths to generate stable widget IDs
- Verify compilation with keypath dependencies

## Running

```bash
# From the iced root directory:
./test_keypath.sh

# Or manually:
cd examples/keypath_test
cargo run
```

## Current Status

This example compiles and runs with the KeyPaths derive macro applied to the state structures. Once the `keypath` feature is implemented in `iced-core`, uncomment the `.id(id_kp!(...))` calls in `src/main.rs` to use stable IDs derived from key paths.

## Dependencies

- `key-paths-derive = "1.0.5"` - Provides `#[derive(KeyPaths)]`
- `key-paths-core = { version = "1.3.0", features = ["tagged_core"] }` - Core trait and types
- `tagged-core = "0.7.0"` - Required dependency

## Next Steps

1. Implement `core/src/widget/keypath.rs` with `id_from_key_path` function
2. Add `keypath` feature to `core/Cargo.toml`
3. Export the `id_kp!` macro from core
4. Uncomment the `.id()` calls in this example
5. Verify stable IDs are generated correctly

