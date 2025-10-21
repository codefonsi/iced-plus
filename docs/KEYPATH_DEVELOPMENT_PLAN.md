# SwiftUI‑like KeyPath in Iced — Step‑by‑Step Development Plan

This document is a concrete, incremental development plan to introduce a SwiftUI‑style KeyPath API to Iced using the `rust-key-paths` crate. It complements, but does not duplicate, the integration guide in `RUST_KEY_PATHS.md`.

- Goal: Ergonomic, typed paths into app state for identity, selection, and updates
- Target feel: SwiftUI `\AppState.user.name` mapped to Rust `kp!(AppState, user.name)`
- Non‑goal: Any rendering/layout changes — this is plumbing and ergonomics only

See also: `RUST_KEY_PATHS.md` for integration points and code examples.

---

## Crate dependency (rust-key-paths)

Add the crate to the crates that will use key paths (generally `core`, `selector`, `runtime`, and any examples that opt in):

```toml
# Cargo.toml
[dependencies]
rust-key-paths = "*"   # use the latest published version
```

And import when needed:

```rust
use rust_key_paths::{kp, KeyPath, KeyPathExt, KeyPathHash};
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
- Adopt `rust-key-paths` for the `KeyPath` trait, `kp!` macro, and helpers.
- Confirm the crate’s stable textual descriptor for hashing (e.g., `"AppState.user.profile.email"`).
- Define the feature flag name in Iced: `keypath` (to gate the integration points).

Deliverable: short ADR in `docs/` linking to this plan.

---

### 1) Core scaffold (trait + macro + IDs)
- Crates/Files:
  - `core/` (new module `core/src/widget/keypath.rs` or inside `core/src/widget/id.rs`)
  - Root proc‑macro crate (if needed) or add dependency on chosen key‑path crate
- Work:
  - Re‑export `KeyPath<T>`, `KeyPathExt`, and `kp!` from `rust-key-paths` in appropriate modules for ergonomics.
  - Implement `id_from_key_path<T>(kp: impl KeyPath<T>) -> widget::Id` using `KeyPathHash::stable_hash64()` from `rust-key-paths`.
  - Provide an `id!(Root, a.b.c)` macro that expands to `id_from_key_path(kp!(Root, a.b.c))`.
  - Gate the new API behind `#[cfg(feature = "keypath")]`.

Acceptance criteria:
- `core` compiles with `--features keypath`
- Unit test proves equal textual paths yield equal IDs

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
use rust_key_paths::{kp, KeyPath, KeyPathHash};

// In core
#[cfg(feature = "keypath")]
pub fn id_from_key_path<T>(kp: impl KeyPath<T>) -> Id { Id::from_u64(kp.stable_hash64()) }

// Convenience macro
#[macro_export]
macro_rules! id { ($root:ty, $($path:tt)+) => { $crate::core::widget::id_from_key_path(kp!($root, $($path)+)) } }

// Selector sugar
pub fn by_key_path<T>(kp: impl KeyPath<T>) -> impl Selector<Output = Target> {
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
