# Iced Documentation

This directory contains design documents, development plans, and guides for Iced development.

## KeyPath Integration

SwiftUI-like key path support for stable, type-safe widget IDs.

### Getting Started

1. **[KEYPATH_QUICKSTART.md](./KEYPATH_QUICKSTART.md)** - Start here! Quick overview and basic usage
2. **[KEYPATH_DEVELOPMENT_PLAN.md](./KEYPATH_DEVELOPMENT_PLAN.md)** - Complete step-by-step implementation plan
3. **[../RUST_KEY_PATHS.md](../RUST_KEY_PATHS.md)** - Technical integration guide with code examples

### Try It Now

```bash
# Run the test script
./test_keypath.sh

# Run the example
cd examples/keypath_test
cargo run
```

## Document Index

| Document | Purpose | Audience |
|----------|---------|----------|
| [KEYPATH_QUICKSTART.md](./KEYPATH_QUICKSTART.md) | Quick start guide | Users & Contributors |
| [KEYPATH_DEVELOPMENT_PLAN.md](./KEYPATH_DEVELOPMENT_PLAN.md) | Implementation plan | Core Contributors |
| [../RUST_KEY_PATHS.md](../RUST_KEY_PATHS.md) | Technical integration | Advanced Contributors |

## Dependencies

The KeyPath integration uses:

- **tagged-core** `0.7.0` - Tagged type system
- **key-paths-core** `1.3.0` - Core traits and types
- **key-paths-derive** `1.0.5` - Derive macro for generating key paths

## Architecture

```
┌─────────────────────────────────────────┐
│         Application State               │
│  #[derive(KeyPaths)]                    │
│  struct AppState {                      │
│      user: User,                        │
│      settings: Settings,                │
│  }                                      │
└─────────────────┬───────────────────────┘
                  │ derive generates
                  ▼
┌─────────────────────────────────────────┐
│     app_state::user::name()             │
│         ↓ returns KeyPath               │
└─────────────────┬───────────────────────┘
                  │ id_from_key_path()
                  ▼
┌─────────────────────────────────────────┐
│       Stable widget::Id                 │
│   (hashed from type + path)             │
└─────────────────┬───────────────────────┘
                  │ used in
                  ▼
┌─────────────────────────────────────────┐
│    Widget .id() method                  │
│    text_input(...).id(id)               │
└─────────────────────────────────────────┘
```

## Implementation Status

### ✅ Completed

- Dependency configuration
- Example structure
- Test scripts
- Documentation

### 🚧 In Progress

- Core module implementation (`core/src/widget/keypath.rs`)
- Feature flag setup
- Unit tests

### 📋 Planned

- Selector API integration
- Runtime helpers
- Widget operation wrappers
- Devtools integration

## Contributing

To contribute to KeyPath integration:

1. Read [KEYPATH_DEVELOPMENT_PLAN.md](./KEYPATH_DEVELOPMENT_PLAN.md)
2. Pick a milestone (preferably in order)
3. Create a feature branch
4. Run `./test_keypath.sh` to verify your changes
5. Submit a PR

### Development Workflow

```bash
# 1. Make changes (e.g., implement core module)
vim core/src/widget/keypath.rs

# 2. Test compilation
cd core
cargo check --features keypath

# 3. Run unit tests
cargo test --features keypath

# 4. Test example
cd ../examples/keypath_test
cargo run

# 5. Run full test suite
cd ../..
./test_keypath.sh
```

## FAQ

### Why key paths?

Key paths provide stable, type-safe identifiers for widgets that survive:
- State reshuffling
- List reordering  
- Code refactoring
- UI rebuilds

### How is this different from manual IDs?

**Manual IDs:**
```rust
text_input("Name", &state.user.name)
    .id(Id::new("user_name")) // ❌ Typo-prone, no type checking
```

**KeyPath IDs:**
```rust
text_input("Name", &state.user.name)
    .id(id_kp!(app_state::user::name())) // ✅ Type-safe, refactor-friendly
```

### When should I use key paths?

Use key paths when you need:
- Stable widget identity across rebuilds
- Testing/automation that targets specific UI elements
- Complex state with nested structures
- Lists that may be reordered or filtered

### What's the performance impact?

Minimal:
- Key path to ID conversion: one hash computation per widget build
- The derive macro generates zero-cost static functions
- No runtime overhead compared to manual `Id::new()`

## Resources

### Iced Core

- [Main README](../README.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [Roadmap](../ROADMAP.md)

### Community

- [Discourse Forum](https://discourse.iced.rs/)
- [Discord](https://discord.gg/3xZJ65GAhd)
- [GitHub Discussions](https://github.com/iced-rs/iced/discussions)

### Related Crates

- [key-paths-core](https://crates.io/crates/key-paths-core)
- [key-paths-derive](https://crates.io/crates/key-paths-derive)
- [tagged-core](https://crates.io/crates/tagged-core)

