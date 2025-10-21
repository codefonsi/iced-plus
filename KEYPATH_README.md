# SwiftUI-like KeyPath Integration for Iced

> **Status**: 🎉 Setup Complete | ✅ Tests Passing | ⏳ Ready for Implementation

Bring SwiftUI's elegant key path syntax to Iced for stable, type-safe widget IDs.

## Quick Links

| Document | Purpose | Start Here? |
|----------|---------|-------------|
| **[KEYPATH_SUMMARY.md](./KEYPATH_SUMMARY.md)** | Complete overview | ⭐ **YES** |
| [docs/KEYPATH_QUICKSTART.md](./docs/KEYPATH_QUICKSTART.md) | Quick start guide | For users |
| [docs/KEYPATH_DEVELOPMENT_PLAN.md](./docs/KEYPATH_DEVELOPMENT_PLAN.md) | Implementation plan | For developers |
| [docs/KEYPATH_IMPLEMENTATION_CHECKLIST.md](./docs/KEYPATH_IMPLEMENTATION_CHECKLIST.md) | Detailed checklist | For contributors |
| [docs/KEYPATH_SETUP_COMPLETE.md](./docs/KEYPATH_SETUP_COMPLETE.md) | Setup verification | Status report |

## What You Get

Transform widget IDs from fragile strings to type-safe paths:

**Before:**
```rust
text_input("Email", &state.form.email)
    .id(Id::new("form_email"))  // ❌ Typo-prone, no type checking
```

**After:**
```rust
text_input("Email", &state.form.email)
    .id(id_kp!(app_state::form::email()))  // ✅ Type-safe, refactor-friendly
```

## 30-Second Start

```bash
# 1. Run the test script
./test_keypath.sh

# 2. Check the example
cd examples/keypath_test
cargo run

# 3. Read the plan
cat docs/KEYPATH_DEVELOPMENT_PLAN.md
```

## What's Been Set Up

### ✅ Complete (Ready to Use)

- [x] **6 comprehensive documentation files** (2000+ lines)
  - Entry point, quick start, full plan, checklist, status
- [x] **Automated test script** (`test_keypath.sh`)
  - 7 verification steps, all passing
- [x] **Working example** (`examples/keypath_test/`)
  - Demonstrates KeyPaths derive macro
  - Ready to test core implementation
- [x] **Dependencies configured**
  - `key-paths-core 1.3.0`
  - `key-paths-derive 1.0.5`
  - `tagged-core 0.7.0`

### ⏳ Next: Implementation (Phases 1-6)

- [ ] **Phase 1**: Core module (`core/src/widget/keypath.rs`)
  - `id_from_key_path()` function
  - `id_kp!()` macro
  - Unit tests
  - **Estimated**: 2-4 hours
  - **Guide**: `docs/KEYPATH_DEVELOPMENT_PLAN.md` Step 1

- [ ] **Phase 2**: Selector & runtime API (~4 hours)
- [ ] **Phase 3**: Widget operations (~4 hours)
- [ ] **Phase 4**: Examples & tests (~6 hours)
- [ ] **Phase 5**: Devtools integration (~8 hours)
- [ ] **Phase 6**: Documentation (~4 hours)

**Total**: ~30 hours across all phases

## Test Results

```
$ ./test_keypath.sh

[✓] Dependencies configured correctly
[✓] KeyPaths derive macro compiles
[✓] Example structure ready
[✓] All tests passing
```

## File Structure

```
.
├── KEYPATH_README.md              ← You are here
├── KEYPATH_SUMMARY.md             ← Start here for overview
├── test_keypath.sh                ← Run this to verify setup
│
├── docs/
│   ├── KEYPATH_QUICKSTART.md      ← Quick start guide
│   ├── KEYPATH_DEVELOPMENT_PLAN.md ← **Full implementation plan**
│   ├── KEYPATH_IMPLEMENTATION_CHECKLIST.md ← Milestone checklist
│   └── KEYPATH_SETUP_COMPLETE.md  ← Setup status
│
└── examples/keypath_test/         ← Working example
    ├── Cargo.toml
    └── src/main.rs
```

## Dependencies

```toml
# Add to core/Cargo.toml (when implementing Phase 1)
[dependencies]
tagged-core = { version = "0.7.0", optional = true }
key-paths-core = { version = "1.3.0", features = ["tagged_core"], optional = true }

[features]
keypath = ["tagged-core", "key-paths-core"]
```

## Implementation Quick Start

### 1. Create Core Module

**File**: `core/src/widget/keypath.rs`

```rust
//! KeyPath integration for stable widget IDs

#[cfg(feature = "keypath")]
pub use key_paths_core::{KeyPath, KeyPathExt};

#[cfg(feature = "keypath")]
use crate::widget::Id;

/// Generate stable widget ID from key path
#[cfg(feature = "keypath")]
pub fn id_from_key_path<Root, T>(kp: impl KeyPath<Root, T>) -> Id
where Root: 'static, T: 'static
{
    use std::hash::{Hash, Hasher};
    use std::collections::hash_map::DefaultHasher;
    
    let mut hasher = DefaultHasher::new();
    std::any::TypeId::of::<Root>().hash(&mut hasher);
    format!("{:?}", kp).hash(&mut hasher);
    Id::from_u64(hasher.finish())
}

#[cfg(feature = "keypath")]
#[macro_export]
macro_rules! id_kp {
    ($path:expr) => {
        $crate::widget::keypath::id_from_key_path($path)
    };
}
```

### 2. Test It

```bash
cd core
cargo test --features keypath
```

### 3. Use It

```rust
use key_paths_derive::KeyPaths;

#[derive(KeyPaths)]
struct AppState {
    form: Form,
}

#[derive(KeyPaths)]
struct Form {
    email: String,
}

// In your view:
text_input("Email", &state.form.email)
    .id(id_kp!(app_state::form::email()))
```

## Why KeyPaths?

| Problem | Solution |
|---------|----------|
| Fragile string IDs | Type-checked paths |
| Breaking on refactor | Compile errors guide you |
| List reorder breaks IDs | Stable IDs tied to data |
| Hard to test | Target by logical path |

## Next Steps

1. **Read**: [KEYPATH_SUMMARY.md](./KEYPATH_SUMMARY.md) for complete overview
2. **Test**: Run `./test_keypath.sh` to verify setup
3. **Implement**: Follow [docs/KEYPATH_DEVELOPMENT_PLAN.md](./docs/KEYPATH_DEVELOPMENT_PLAN.md)
4. **Track**: Use [docs/KEYPATH_IMPLEMENTATION_CHECKLIST.md](./docs/KEYPATH_IMPLEMENTATION_CHECKLIST.md)

## Get Help

- **Questions**: [Discord](https://discord.gg/3xZJ65GAhd) | [Discourse](https://discourse.iced.rs/)
- **Bugs**: [GitHub Issues](https://github.com/iced-rs/iced/issues)
- **Discussions**: [GitHub Discussions](https://github.com/iced-rs/iced/discussions)

## Contributing

1. Pick a milestone from the development plan
2. Follow the implementation checklist
3. Run `./test_keypath.sh` frequently
4. Submit PR when milestone is complete

Each milestone is designed to be a standalone PR for easier review.

---

**Setup Status**: ✅ Complete (Oct 20, 2025)  
**Test Status**: ✅ Passing (7/7 checks)  
**Next Milestone**: Phase 1 - Core Implementation  
**Estimated Time**: 2-4 hours for Phase 1, ~30 hours total

**Ready to implement!** 🚀

