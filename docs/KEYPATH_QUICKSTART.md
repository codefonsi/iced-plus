# KeyPath Integration - Quick Start Guide

This is a quick reference for getting started with KeyPath integration in Iced.

## What You Get

SwiftUI-like syntax for stable widget IDs in Rust:

```rust
// SwiftUI
Text($state.user.name)
    .id(\AppState.user.name)

// Iced with KeyPath (after implementation)
text_input("Name", &state.user.name)
    .id(id_kp!(app_state::user::name()))
```

## Dependencies

```toml
[dependencies]
tagged-core = "0.7.0"
key-paths-core = { version = "1.3.0", features = ["tagged_core"] }
key-paths-derive = "1.0.5"
```

## Basic Usage

### 1. Derive KeyPaths on your state

```rust
use key_paths_derive::KeyPaths;

#[derive(KeyPaths)]
struct AppState {
    user: User,
    settings: Settings,
}

#[derive(KeyPaths)]
struct User {
    name: String,
    email: String,
}
```

### 2. Use key paths for stable IDs (once implemented)

```rust
fn view(state: &AppState) -> Element<Message> {
    column![
        text_input("Name", &state.user.name)
            .id(id_kp!(app_state::user::name())),
            
        text_input("Email", &state.user.email)
            .id(id_kp!(app_state::user::email())),
    ]
}
```

## Testing

Run the test script to verify everything is set up correctly:

```bash
./test_keypath.sh
```

## Current Status

✅ Dependencies configured  
✅ Test example created  
✅ Derive macro tested  
⏳ Core implementation (see KEYPATH_DEVELOPMENT_PLAN.md)  
⏳ Selector API  
⏳ Widget operations  

## Next Steps

1. Read [`docs/KEYPATH_DEVELOPMENT_PLAN.md`](./KEYPATH_DEVELOPMENT_PLAN.md) for full implementation plan
2. Start with Milestone 1: Core scaffold
3. Run `./test_keypath.sh` to verify each step
4. See `examples/keypath_test/` for a working example

## Files to Read

- **[KEYPATH_DEVELOPMENT_PLAN.md](./KEYPATH_DEVELOPMENT_PLAN.md)** - Complete development plan with milestones
- **[../RUST_KEY_PATHS.md](../RUST_KEY_PATHS.md)** - Integration guide with code examples  
- **[examples/keypath_test/](../examples/keypath_test/)** - Test example ready to run
- **[test_keypath.sh](../test_keypath.sh)** - Automated test script

## Why KeyPaths?

### Problems Solved

1. **Stable IDs across rebuilds** - IDs are derived from data structure, not rendering order
2. **Type safety** - Compile-time verification of paths into your state
3. **Refactoring friendly** - Rename a field, get compile errors where it's used
4. **Testing** - Record/replay interactions by logical path, not brittle selectors

### Example: List Reordering

Without KeyPaths:
```rust
// IDs break when list is sorted differently
items.iter().enumerate().map(|(i, item)| {
    text(&item.name).id(Id::new(i)) // ❌ Fragile!
})
```

With KeyPaths:
```rust
// IDs stay stable because they're tied to data
items.iter().map(|item| {
    text(&item.name).id(id_kp!(/* path to item */)) // ✅ Stable!
})
```

## Support

- Issues: [GitHub Issues](https://github.com/iced-rs/iced/issues)
- Discussions: [Discourse Forum](https://discourse.iced.rs/)
- Chat: [Discord](https://discord.gg/3xZJ65GAhd)

