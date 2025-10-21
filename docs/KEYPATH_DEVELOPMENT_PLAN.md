# SwiftUI‑like KeyPath in Iced — Step‑by‑Step Development Plan

This document is a concrete, incremental development plan to introduce a SwiftUI‑style KeyPath API to Iced using the `key-paths-core` and `key-paths-derive` crates. It complements, but does not duplicate, the integration guide in `RUST_KEY_PATHS.md`.

- Goal: Ergonomic, typed paths into app state for identity, selection, and updates
- Target feel: SwiftUI `\AppState.user.name` mapped to Rust derived key paths
- Non‑goal: Any rendering/layout changes — this is plumbing and ergonomics only

See also: `RUST_KEY_PATHS.md` for integration points and code examples.

---

## Crate dependencies (key-paths-core + key-paths-derive)

Add these crates to the crates that will use key paths (generally `core`, `selector`, `runtime`, and any examples that opt in):

```toml
# Cargo.toml
[dependencies]
tagged-core = "0.7.0"
key-paths-core = { version = "1.3.0", features = ["tagged_core"] }
key-paths-derive = "1.0.5"
```

And import when needed:

```rust
use key_paths_core::{KeyPath, KeyPathExt};
use key_paths_derive::KeyPaths;
```

The derive macro approach:

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

// Usage:
// app_state::user::name() returns a typed key path to AppState.user.name
```

## High‑level milestones

1) Core scaffold (trait + macro + IDs)
2) Selector and runtime API for lookup by key path
3) Common widget operations (focus, scroll, etc.) by key path
4) Examples and tests (compile‑time + runtime)
5) Devtools/tester integration (record/replay)
6) Documentation and migration notes

Each milestone should land as its own PR and be behind a `keypath` Cargo feature to keep the change non‑breaking.

---

## Target syntax and API surface

- Construct a typed key path:

```rust
// SwiftUI: \AppState.user.name
// Rust (proc macro):
let p = kp!(AppState, user.name);
```

- Produce stable widget `Id` from a key path:

```rust
let id = id_from_key_path(kp!(AppState, form.email));
```

- Convenience macro for brevity in `view()`:

```rust
text_input("Email", &state.form.email).id(id!(AppState, form.email));
```

- Optional get/set ergonomics (lensy helpers) for app `update`:

```rust
kp!(AppState, user.profile.name).set(state, new_name);
let email = kp!(AppState, user.profile.email).get(state).clone();
```

---

## Detailed plan (step‑by‑step)

### 0) Design decisions (short RFC)
- Adopt `key-paths-core` (v1.3.0) + `key-paths-derive` (v1.0.5) for the `KeyPath` trait and derive macro.
- Use `tagged-core` (v0.7.0) as required by key-paths-core features.
- Leverage compile-time type safety from the derive macro approach.
- Define the feature flag name in Iced: `keypath` (to gate the integration points).

Deliverable: short ADR in `docs/` linking to this plan.

---

### 1) Core scaffold (trait + macro + IDs)
- Crates/Files:
  - `core/Cargo.toml` (add dependencies)
  - `core/src/widget/keypath.rs` (new module)
  - `core/src/widget.rs` or `core/src/widget/mod.rs` (expose module)
- Work:
  - Add dependencies to `core/Cargo.toml`:
    ```toml
    [dependencies]
    tagged-core = { version = "0.7.0", optional = true }
    key-paths-core = { version = "1.3.0", features = ["tagged_core"], optional = true }
    
    [features]
    keypath = ["tagged-core", "key-paths-core"]
    ```
  - Create `core/src/widget/keypath.rs`:
    - Re‑export `KeyPath`, `KeyPathExt` from `key-paths-core`
    - Implement `id_from_key_path<Root, T>(kp: impl KeyPath<Root, T>) -> widget::Id` using a hash of the key path's string representation
    - Provide helper macro `id_kp!(path)` for ergonomic use
  - Gate the new API behind `#[cfg(feature = "keypath")]`

Acceptance criteria:
- `core` compiles with `--features keypath`
- Unit test proves equal key paths yield equal IDs
- Test script verifies basic functionality

---

### 2) Selector and runtime API
- Crates/Files:
  - `selector/src/lib.rs`, `selector/src/find.rs`, `selector/src/target.rs`
  - `runtime/src/widget/selector.rs`
- Work:
  - Add `by_key_path<T>(kp: impl KeyPath<T>) -> impl Selector<Output = Target>` reusing `id_from_key_path`.
  - Add `find_by_key_path<T>(kp: impl KeyPath<T>) -> Task<Option<Target>>` in runtime.

Acceptance criteria:
- Simple async example can `find_by_key_path(kp!(AppState, form.email))` and obtain a `Target`.

---

### 3) Widget operations by key path
- Crates/Files:
  - `core/src/widget/operation.rs` and related operation adapters
  - Specific widgets as needed (e.g., `widget/src/text_input.rs`, `widget/src/scrollable.rs`)
- Work:
  - Introduce small `Operation` wrappers that match on `Id` derived from key paths (e.g., focus a `TextInput`, scroll a `Scrollable`).
  - Keep these utilities tiny and composable; do not change widget cores.

Acceptance criteria:
- Programmatically focus a `TextInput` via `FocusByKeyPath::new(kp!(AppState, form.email))`.
- Scroll via a similar adapter.

---

### 4) Examples and tests
- Crates/Files:
  - `examples/*` (add a new `keypath/` example or update `text_input` and `todos`)
  - `tester/`, `devtools/` (basic checks)
- Work:
  - Add an example demonstrating IDs and selection derived from key paths.
  - Compile‑time tests: invalid paths fail to compile; valid paths type‑check.
  - Runtime tests: stable IDs across rebuilds, list reorders, etc.

Acceptance criteria:
- CI job runs examples with `--features keypath`.
- Tests cover ID stability and selector behavior.

---

### 5) Devtools/tester integration (optional but recommended)
- Crates/Files:
  - `tester/src/recorder.rs`, `devtools/src/*`
- Work:
  - Record actions using key‑path strings (e.g., `"AppState.form.email"`).
  - On replay, resolve the recorded path to `Id` with `id_from_key_path`.

Acceptance criteria:
- Recorded click on a text input can be replayed after list reorder.

---

### 6) Documentation and migration
- Crates/Files:
  - `RUST_KEY_PATHS.md` (link back to implemented APIs)
  - `book`/docs site (if applicable)
- Work:
  - Document feature flag usage and examples of common operations.
  - Add guidance on lists: prefer stable item IDs over indices in paths.
  - Provide a migration note showing how to replace ad‑hoc IDs with `id!(...)`.

Acceptance criteria:
- Minimal docs PR with runnable code snippets.

---

## API sketches (illustrative)

```rust
use key_paths_core::{KeyPath, KeyPathExt};
use key_paths_derive::KeyPaths;
use std::hash::{Hash, Hasher};
use std::collections::hash_map::DefaultHasher;

// In core/src/widget/keypath.rs
#[cfg(feature = "keypath")]
pub fn id_from_key_path<Root, T>(kp: impl KeyPath<Root, T>) -> Id 
where
    Root: 'static,
    T: 'static,
{
    // Hash the type ID and path string representation
    let mut hasher = DefaultHasher::new();
    std::any::TypeId::of::<Root>().hash(&mut hasher);
    format!("{:?}", kp).hash(&mut hasher);
    Id::from_u64(hasher.finish())
}

// Helper macro for ergonomic ID generation
#[macro_export]
macro_rules! id_kp {
    ($path:expr) => {
        $crate::widget::keypath::id_from_key_path($path)
    };
}

// Example usage with derive:
#[derive(KeyPaths)]
struct AppState {
    user: User,
    form: Form,
}

#[derive(KeyPaths)]
struct User {
    name: String,
    email: String,
}

#[derive(KeyPaths)]
struct Form {
    email: String,
    password: String,
}

// In your view function:
fn view(state: &AppState) -> Element<Message> {
    text_input("Email", &state.form.email)
        .id(id_kp!(app_state::form::email()))
        .into()
}

// Selector sugar
pub fn by_key_path<Root, T>(kp: impl KeyPath<Root, T>) -> impl Selector<Output = Target> 
where
    Root: 'static,
    T: 'static,
{
    by_id(id_from_key_path(kp))
}
```

---

## Stability, performance, and safety
- Stability: The hash must be derived from a stable textual description, not memory addresses.
- Collections: Provide adapters for stable keys (e.g., `items.by_id(item.id)`), avoid plain indices when possible.
- Performance: Compute the hash once per element build; cache if necessary.
- Send/Sync: Ensure key‑path values are `Send + Sync + 'static` for cross‑thread tasks.

---

## Rollout plan (PR sequencing)
1. Core scaffold behind `keypath` feature (trait/macro + `id_from_key_path`).
2. Selector/runtime helpers.
3. Operation adapters for focus/scroll.
4. Example(s) + tests.
5. Devtools/tester.
6. Docs + migration note.

---

## Acceptance checklist (per repo)
- Feature‑gated builds pass on CI.
- Examples demonstrate SwiftUI‑like ergonomics.
- No breaking changes to existing public APIs when `keypath` is disabled.
- Clear docs guiding users to prefer stable key components over indices.

---

## Quick Start: Implementation Guide

### Testing Current Setup

Run the test script to verify dependencies and example structure:

```bash
./test_keypath.sh
```

This will:
- Verify keypath dependencies are correctly configured
- Check that the KeyPaths derive macro compiles
- Build and briefly run the test example
- Report on implementation status

### Step 1: Implement Core Module

Create `core/src/widget/keypath.rs`:

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

/// Generate a stable widget ID from a key path
#[cfg(feature = "keypath")]
pub fn id_from_key_path<Root, T>(kp: impl KeyPath<Root, T>) -> Id
where
    Root: 'static,
    T: 'static,
{
    let mut hasher = DefaultHasher::new();
    
    // Hash the root type for uniqueness
    std::any::TypeId::of::<Root>().hash(&mut hasher);
    
    // Hash the debug representation of the key path
    // This gives us a stable string like "app_state::user::name"
    format!("{:?}", kp).hash(&mut hasher);
    
    Id::from_u64(hasher.finish())
}

/// Convenience macro for generating IDs from key paths
#[cfg(feature = "keypath")]
#[macro_export]
macro_rules! id_kp {
    ($path:expr) => {
        $crate::widget::keypath::id_from_key_path($path)
    };
}
```

Add to `core/src/widget/mod.rs` or `core/src/widget.rs`:

```rust
#[cfg(feature = "keypath")]
pub mod keypath;
```

Update `core/Cargo.toml`:

```toml
[dependencies]
# ... existing dependencies ...
tagged-core = { version = "0.7.0", optional = true }
key-paths-core = { version = "1.3.0", features = ["tagged_core"], optional = true }

[features]
# ... existing features ...
keypath = ["tagged-core", "key-paths-core"]
```

### Step 2: Test the Implementation

1. Uncomment the `.id()` calls in `examples/keypath_test/src/main.rs`
2. Update `examples/keypath_test/Cargo.toml` to enable the feature:
   ```toml
   iced = { path = "../..", features = ["keypath"] }
   ```
3. Run the test:
   ```bash
   cd examples/keypath_test
   cargo run --features keypath
   ```

### Step 3: Verify Stable IDs

Add a test in `core/src/widget/keypath.rs`:

```rust
#[cfg(all(test, feature = "keypath"))]
mod tests {
    use super::*;
    use key_paths_derive::KeyPaths;
    
    #[derive(KeyPaths)]
    struct TestState {
        user: User,
    }
    
    #[derive(KeyPaths)]
    struct User {
        name: String,
        email: String,
    }
    
    #[test]
    fn test_same_path_same_id() {
        let id1 = id_from_key_path(test_state::user::name());
        let id2 = id_from_key_path(test_state::user::name());
        assert_eq!(id1, id2, "Same key path should generate same ID");
    }
    
    #[test]
    fn test_different_paths_different_ids() {
        let id_name = id_from_key_path(test_state::user::name());
        let id_email = id_from_key_path(test_state::user::email());
        assert_ne!(id_name, id_email, "Different key paths should generate different IDs");
    }
}
```

Run tests:
```bash
cd core
cargo test --features keypath
```

### Step 4: Proceed with Development Plan

Continue with the remaining milestones from the development plan above:
- Milestone 2: Selector and runtime API
- Milestone 3: Widget operations
- Milestone 4: Additional examples and tests
- Milestone 5: Devtools integration
- Milestone 6: Documentation

---

## Troubleshooting

### Compilation Errors

If you encounter errors about missing types:
- Ensure `keypath` feature is enabled: `cargo build --features keypath`
- Verify all dependencies are added to `Cargo.toml`
- Check that `key-paths-derive = "1.0.5"` is present

### KeyPaths derive not generating modules

The derive macro generates lowercase module paths:
- `AppState` → `app_state::`
- Field `userName` → `user_name::`
- Use `app_state::user::name()` not `AppState::user::name()`

### Hash collisions

If you experience ID collisions:
- The current implementation uses `DefaultHasher` which should be sufficient
- For production, consider using a cryptographic hash for stronger guarantees
- Ensure your state types are unique (`TypeId::of::<Root>()` is included in the hash)

