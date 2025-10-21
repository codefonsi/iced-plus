# KeyPath Implementation Checklist

This is a practical, step-by-step checklist for implementing KeyPath support in Iced. Check off each item as you complete it.

## Prerequisites

- [ ] Read [KEYPATH_QUICKSTART.md](./KEYPATH_QUICKSTART.md)
- [ ] Read [KEYPATH_DEVELOPMENT_PLAN.md](./KEYPATH_DEVELOPMENT_PLAN.md)
- [ ] Run `./test_keypath.sh` to verify current status
- [ ] Understand the `key-paths-derive` macro (test in `examples/keypath_test`)

---

## Milestone 1: Core Scaffold

### 1.1 Add Dependencies to Core

- [ ] Edit `core/Cargo.toml`
- [ ] Add under `[dependencies]`:
  ```toml
  tagged-core = { version = "0.7.0", optional = true }
  key-paths-core = { version = "1.3.0", features = ["tagged_core"], optional = true }
  ```
- [ ] Add under `[features]`:
  ```toml
  keypath = ["tagged-core", "key-paths-core"]
  ```
- [ ] Test: `cd core && cargo check --features keypath`

### 1.2 Create KeyPath Module

- [ ] Create file: `core/src/widget/keypath.rs`
- [ ] Add module header and imports:
  ```rust
  //! KeyPath integration for stable widget IDs
  
  #[cfg(feature = "keypath")]
  pub use key_paths_core::{KeyPath, KeyPathExt};
  
  #[cfg(feature = "keypath")]
  use crate::widget::Id;
  #[cfg(feature = "keypath")]
  use std::hash::{Hash, Hasher};
  #[cfg(feature = "keypath")]
  use std::collections::hash_map::DefaultHasher;
  ```
- [ ] Implement `id_from_key_path` function (see [KEYPATH_DEVELOPMENT_PLAN.md](./KEYPATH_DEVELOPMENT_PLAN.md#step-1-implement-core-module))
- [ ] Add `id_kp!` macro
- [ ] Test: `cargo check --features keypath`

### 1.3 Expose Module

- [ ] Find `core/src/widget/mod.rs` or `core/src/widget.rs`
- [ ] Add: `#[cfg(feature = "keypath")] pub mod keypath;`
- [ ] Test: `cd core && cargo build --features keypath`

### 1.4 Add Unit Tests

- [ ] Add test module to `core/src/widget/keypath.rs`
- [ ] Implement `test_same_path_same_id` test
- [ ] Implement `test_different_paths_different_ids` test
- [ ] Test: `cargo test --features keypath`
- [ ] Verify all tests pass

### 1.5 Update Root Cargo.toml (if needed)

- [ ] Check if root `Cargo.toml` needs `keypath` feature passthrough
- [ ] Add feature to workspace members if needed
- [ ] Test: `cargo build --features keypath` from root

### 1.6 Milestone 1 Verification

- [ ] Run `./test_keypath.sh` - should report core module exists
- [ ] All core tests pass: `cd core && cargo test --features keypath`
- [ ] Example compiles: `cd examples/keypath_test && cargo check`
- [ ] Create PR for Milestone 1

---

## Milestone 2: Selector and Runtime API

### 2.1 Update Selector Crate

- [ ] Edit `selector/Cargo.toml`
- [ ] Add optional dependencies (same as core)
- [ ] Add `keypath` feature
- [ ] Test: `cd selector && cargo check --features keypath`

### 2.2 Add `by_key_path` Function

- [ ] Edit `selector/src/lib.rs`
- [ ] Import necessary types
- [ ] Implement `by_key_path<Root, T>` function
- [ ] Test compilation

### 2.3 Update Runtime Crate

- [ ] Edit `runtime/Cargo.toml`
- [ ] Add optional dependencies and feature
- [ ] Edit `runtime/src/widget/selector.rs`
- [ ] Implement `find_by_key_path` function
- [ ] Test: `cd runtime && cargo check --features keypath`

### 2.4 Add Integration Tests

- [ ] Create test file: `runtime/tests/keypath_selector.rs`
- [ ] Write test for `find_by_key_path`
- [ ] Verify selector returns correct `Target`
- [ ] Test: `cargo test --features keypath`

### 2.5 Milestone 2 Verification

- [ ] Selector tests pass
- [ ] Runtime tests pass
- [ ] Example can use `find_by_key_path` (create test case)
- [ ] Create PR for Milestone 2

---

## Milestone 3: Widget Operations

### 3.1 Create Operation Wrappers

- [ ] Edit `core/src/widget/operation.rs` (or create new module)
- [ ] Implement `FocusByKeyPath` operation
- [ ] Implement `ScrollByKeyPath` operation
- [ ] Add helper functions: `focus_by_key_path()`, `scroll_by_key_path()`

### 3.2 Widget-Specific Operations

- [ ] Review `widget/src/text_input.rs` for focus operations
- [ ] Review `widget/src/scrollable.rs` for scroll operations  
- [ ] Add KeyPath variants where appropriate
- [ ] Test: `cd widget && cargo check --features keypath`

### 3.3 Add Operation Tests

- [ ] Create test: focus text input by key path
- [ ] Create test: scroll scrollable by key path
- [ ] Verify operations work correctly
- [ ] Test: `cargo test --features keypath`

### 3.4 Milestone 3 Verification

- [ ] Operation tests pass
- [ ] Can programmatically focus widgets via key paths
- [ ] Can programmatically scroll via key paths
- [ ] Create PR for Milestone 3

---

## Milestone 4: Examples and Tests

### 4.1 Update Test Example

- [ ] Edit `examples/keypath_test/src/main.rs`
- [ ] Uncomment all `.id(id_kp!(...))` calls
- [ ] Update `Cargo.toml` to use `iced = { path = "../..", features = ["keypath"] }`
- [ ] Test: `cargo run`
- [ ] Verify app runs without errors

### 4.2 Create Comprehensive Example

- [ ] Create new example: `examples/keypath_demo/`
- [ ] Demonstrate:
  - [ ] Stable IDs in static widgets
  - [ ] Stable IDs in dynamic lists
  - [ ] Reordering/filtering lists
  - [ ] Selector API usage
  - [ ] Operation API usage
- [ ] Add README explaining features
- [ ] Test: run and verify all features work

### 4.3 Add Compile-Time Tests

- [ ] Create `core/tests/ui/keypath_compile_fail/`
- [ ] Add test: invalid key path should not compile
- [ ] Add test: type mismatch should not compile
- [ ] Use `trybuild` or similar for compile-fail tests

### 4.4 Add Runtime Tests

- [ ] Test: stable IDs across rebuilds
- [ ] Test: stable IDs with list reordering
- [ ] Test: ID uniqueness for different paths
- [ ] Test: ID collision detection (if applicable)

### 4.5 Milestone 4 Verification

- [ ] All examples run successfully
- [ ] Compile-time tests verify type safety
- [ ] Runtime tests verify stability
- [ ] Update `test_keypath.sh` to run new tests
- [ ] Create PR for Milestone 4

---

## Milestone 5: Devtools/Tester Integration

### 5.1 Update Tester Crate

- [ ] Edit `tester/Cargo.toml` - add keypath dependencies
- [ ] Edit `tester/src/recorder.rs`
- [ ] Add key path recording support
- [ ] Store paths as strings in recording format

### 5.2 Implement Replay

- [ ] Add key path resolution in replay
- [ ] Convert stored path strings back to IDs
- [ ] Use selector API to find widgets
- [ ] Test recording and replay

### 5.3 Update Devtools

- [ ] Edit `devtools/Cargo.toml`
- [ ] Add key path display in devtools UI
- [ ] Show widget ID and corresponding key path
- [ ] Test devtools with keypath example

### 5.4 Add Tests

- [ ] Test: record interaction via key path
- [ ] Test: replay after list reorder
- [ ] Test: replay after UI rebuild
- [ ] Verify robustness

### 5.5 Milestone 5 Verification

- [ ] Can record interactions by key path
- [ ] Replay works after reordering
- [ ] Devtools displays key paths
- [ ] Create PR for Milestone 5

---

## Milestone 6: Documentation

### 6.1 Update API Documentation

- [ ] Add rustdoc to `core/src/widget/keypath.rs`
- [ ] Add examples to function docs
- [ ] Document the `id_kp!` macro
- [ ] Add module-level documentation
- [ ] Test: `cargo doc --features keypath --open`

### 6.2 Update User Guides

- [ ] Update [KEYPATH_QUICKSTART.md](./KEYPATH_QUICKSTART.md) with final API
- [ ] Update [KEYPATH_DEVELOPMENT_PLAN.md](./KEYPATH_DEVELOPMENT_PLAN.md) status
- [ ] Update [RUST_KEY_PATHS.md](../RUST_KEY_PATHS.md) with real implementations
- [ ] Add migration guide for existing code

### 6.3 Update Examples README

- [ ] Add keypath examples to `examples/README.md`
- [ ] Describe what each example demonstrates
- [ ] Link to relevant documentation

### 6.4 Create Migration Guide

- [ ] Create `docs/KEYPATH_MIGRATION.md`
- [ ] Document how to migrate from manual IDs
- [ ] Show before/after examples
- [ ] List breaking changes (if any)
- [ ] Provide troubleshooting tips

### 6.5 Update CHANGELOG

- [ ] Add keypath feature to `CHANGELOG.md`
- [ ] List new APIs
- [ ] Note feature flag requirement
- [ ] Mention dependencies

### 6.6 Milestone 6 Verification

- [ ] All documentation is accurate and up-to-date
- [ ] Code examples in docs compile and run
- [ ] Migration guide is clear and helpful
- [ ] Create PR for Milestone 6

---

## Final Checks

### Integration Testing

- [ ] Run all tests: `cargo test --all-features`
- [ ] Run all examples: `cargo run --example <name> --features keypath`
- [ ] Run `./test_keypath.sh` - all checks pass
- [ ] Test on all supported platforms (Linux, macOS, Windows)

### Code Quality

- [ ] Run `cargo clippy --all-features`
- [ ] Fix all clippy warnings
- [ ] Run `cargo fmt --all`
- [ ] Ensure consistent formatting

### Feature Flag Verification

- [ ] Build without keypath feature: `cargo build` (should succeed)
- [ ] Build with keypath feature: `cargo build --features keypath` (should succeed)
- [ ] Verify no breaking changes when feature is disabled

### Documentation

- [ ] All public APIs have rustdoc
- [ ] Examples are runnable and well-commented
- [ ] README files are up-to-date
- [ ] Links in documentation are valid

### Performance

- [ ] Benchmark ID generation (if applicable)
- [ ] Verify no performance regression in core rendering
- [ ] Check memory usage with large state trees

---

## Release Preparation

- [ ] Update version numbers (if needed)
- [ ] Update CHANGELOG.md with complete feature description
- [ ] Create comprehensive PR description
- [ ] Request reviews from core maintainers
- [ ] Address review feedback
- [ ] Merge to main branch
- [ ] Tag release (if applicable)
- [ ] Announce feature in community channels

---

## Post-Release

- [ ] Monitor for bug reports
- [ ] Answer questions in Discord/Discourse
- [ ] Write blog post or tutorial (optional)
- [ ] Update Iced book with keypath chapter (if applicable)
- [ ] Collect user feedback for improvements

---

## Notes

- Each milestone should be a separate PR for easier review
- Run `./test_keypath.sh` frequently to catch issues early
- Keep commits atomic and well-documented
- Update this checklist as you discover new tasks
- Don't hesitate to ask for help in Discord/Discourse

## Quick Commands Reference

```bash
# Test everything
./test_keypath.sh

# Test specific crate
cd core && cargo test --features keypath

# Run example
cd examples/keypath_test && cargo run

# Build with feature
cargo build --features keypath

# Check without building
cargo check --features keypath

# Lint
cargo clippy --all-features

# Format
cargo fmt --all

# Generate docs
cargo doc --features keypath --open
```

