## Rust Key Paths integration guide

This repo is a Rust UI toolkit organized as multiple crates (core/runtime/widget/selector/etc.). It already exposes a generic selection API and widget state tree that are ideal anchor points for adding strongly-typed "key paths" (Swift-like field pointers/lenses).

Below are the recommended integration points, with file paths and examples. Replace the key path crate API to match your choice (e.g., `rust-key-paths`, `keypath`, `lens-rs`). The examples use a placeholder macro `kp!()` and trait `KeyPath` for clarity.

### What you can do with key paths here
- **Stable widget identity**: Derive `widget::Id` from a typed path into your app state.
- **Typed selection**: Find widgets or regions using a key path instead of ad‑hoc strings or indices.
- **State updates**: Read/update nested state via a path (lenses) during `update` and in widget `Operation`s.
- **Testing/devtools**: Record and replay interactions targeting key paths.

---

## 1) Widget identity (IDs)
- Files: `core/src/widget/id.rs`, builders like `widget/src/text_input.rs` (`TextInput::id`), other widgets exposing `.id(...)`.
- Goal: Produce a `widget::Id` from a key path to a specific piece of state so that identity is stable across rebuilds and reordering.

Example helper (add in `core/src/widget/id.rs` or a small `core/src/widget/keypath.rs` module):
```rust
use crate::widget::Id;
use your_keypath_crate::{KeyPath, KeyPathHash};

pub fn id_from_key_path<T>(kp: impl KeyPath<T>) -> Id {
    // Use a stable 64-bit hash of the key path descriptor
    let h = kp.stable_hash64();
    Id::from_u64(h)
}
```

Usage in a widget (e.g., `TextInput` in your view):
```rust
use your_keypath_crate::kp;
use core::widget::id_from_key_path;

text_input("Name", &state.user.name)
    .id(id_from_key_path(kp!(AppState, user.name)))
```

Impact: You can now use selectors by ID even when lists reorder, because the ID follows the data, not the index.

---

## 2) Selector API: find by key path
- Files: `selector/src/lib.rs`, `selector/src/find.rs`, `selector/src/target.rs`, `runtime/src/widget/selector.rs`
- Goal: Add an ergonomic way to find widgets with a key path.

Add a convenience `Selector` constructor:
```rust
// selector/src/lib.rs
use your_keypath_crate::KeyPath;
use crate::core::widget;

pub fn by_key_path<T>(kp: impl KeyPath<T>) -> impl Selector<Output = Target> {
    let id = crate::id(id_from_key_path(kp)); // reuse helper from section 1
    id
}
```

Runtime task wrappers:
```rust
// runtime/src/widget/selector.rs
pub fn find_by_key_path<T>(kp: impl KeyPath<T>) -> Task<Option<Target>> {
    task::widget(selector::by_key_path(kp).find())
}
```

Now you can:
```rust
let target = find_by_key_path(kp!(AppState, form.email)).await;
```

---

## 3) Widget tree operations with key paths
- Files: `core/src/widget/operation.rs`, `selector/src/find.rs`
- Goal: Target inner widget state (focus, scroll, text input) by key path using existing `Operation` hooks.

Pattern:
```rust
use core::widget::{Operation, Id};
use core::{Rectangle, Vector};
use your_keypath_crate::KeyPath;

pub struct FocusByKeyPath<KP> { id: Id, _kp: KP }

impl<KP> FocusByKeyPath<KP> {
    pub fn new(kp: KP) -> Self where KP: KeyPath<AppState> {
        Self { id: id_from_key_path(kp), _kp: kp }
    }
}

impl Operation for FocusByKeyPath<impl KeyPath<AppState>> {
    fn focusable(&mut self, id: Option<&Id>, _b: Rectangle, state: &mut dyn Focusable) {
        if id == Some(&self.id) { state.focus(); }
    }
    fn traverse(&mut self, operate: &mut dyn FnMut(&mut dyn Operation)) { operate(self); }
}
```
Then drive it with existing runtime plumbing that applies operations to the UI tree.

---

## 4) Application state updates via lenses (key paths)
- Files: your app crates (e.g., `examples/*/src/main.rs`), update handlers
- Goal: Replace manual nested `match`/`struct` updates with `kp` getters/setters.

```rust
use your_keypath_crate::{kp, KeyPathExt};

// Set
kp!(AppState, user.profile.name).set(state, new_name);

// Get
let email = kp!(AppState, user.profile.email).get(state).clone();
```

This is orthogonal to I/O rendering, but complements how IDs/selectors are derived.

---

## 5) Lists and dynamic children
- Files: any container building children (e.g., your `view()`s), `widget/src/keyed/*`, `core/src/widget/tree.rs`
- Goal: Generate stable IDs for items in a list from a key path to the item itself (not the index).

Example:
```rust
row(
    state.items.iter().enumerate().map(|(i, item)| {
        let id = id_from_key_path(kp!(AppState, items[i]));
        text_input("Item", &item.title).id(id).into()
    })
)
```
Prefer a key path using a stable item id (e.g., `items.by_id(item.id)` adapter) to avoid index drift.

---

## 6) Widget-specific states (TextInput, Scrollable, etc.)
- Files: `widget/src/text_input.rs`, `widget/src/scrollable.rs`, `core/src/widget/operation/*`
- Goal: Provide helpers that map a key path straight to common operations.

Examples:
```rust
pub fn focus_text_input(kp: impl KeyPath<AppState>) -> impl Operation {
    FocusByKeyPath::new(kp)
}

pub fn scroll_to_top(kp: impl KeyPath<AppState>) -> impl Operation {
    struct Op { id: Id }
    impl Operation for Op {
        fn scrollable(&mut self, id: Option<&Id>, _b: Rectangle, _cb: Rectangle, _t: Vector, s: &mut dyn Scrollable) {
            if id == Some(&self.id) { s.scroll_to(0.0); }
        }
        fn traverse(&mut self, o: &mut dyn FnMut(&mut dyn Operation)) { o(self); }
    }
    Op { id: id_from_key_path(kp) }
}
```

---

## 7) Pane grid routing
- Files: `widget/src/pane_grid/state.rs`
- Goal: Map a key path to a pane’s inner state so panes/actions can be referenced robustly.

Pattern: define an adapter `kp!(AppState, panes[PaneId(…)]/* your field */)` or build a helper to convert a pane’s stable key to `Pane` and derive `Id` accordingly for the pane’s container widget.

---

## 8) Testing and devtools
- Files: `tester/src/recorder.rs`, `devtools/src/*`
- Goal: Record interactions and resolve them by key path at replay time instead of screen coordinates or text.

Example recorded step:
```json
{"action":"click","at":"AppState.form.email"}
```
On replay, compute `Id` from the recorded key path and use `find_by_id`/`find_by_key_path` to drive events.

---

## 9) Minimal wiring checklist
- Add dependency where needed (widget/selector/runtime/app crates):
```toml
# Cargo.toml
[dependencies]
rust-key-paths = "*"    # or your chosen key-path crate
```
- Implement `id_from_key_path` once (Section 1) and reuse.
- Expose `find_by_key_path` in `runtime/src/widget/selector.rs` (Section 2).
- Add small `Operation` helpers for common tasks (Section 3/6).
- Start assigning IDs from key paths in your `view()` functions.

---

## 10) Notes and pitfalls
- **Stability**: Ensure the key path description you hash is stable across builds (avoid including memory addresses). Most crates expose a stable textual path.
- **Collections**: Prefer key paths that use your item’s own stable ID instead of `[index]`.
- **Performance**: Compute IDs once per element build; avoid recomputing heavy hashes in hot paths.
- **Ergonomics**: Create domain-specific helpers, e.g., `id!(form.email)` macro that expands to `id_from_key_path(kp!(AppState, form.email))`.

---

## Relevant files in this repo
- `core/src/widget.rs`, `core/src/widget/tree.rs`, `core/src/widget/operation.rs`
- `core/src/element.rs`, `runtime/src/user_interface.rs`
- `selector/src/lib.rs`, `selector/src/find.rs`, `selector/src/target.rs`
- `runtime/src/widget/selector.rs`
- Widgets exposing IDs and operations, e.g., `widget/src/text_input.rs`, `widget/src/scrollable.rs`, `widget/src/pane_grid/state.rs`

These are the natural places to thread key paths through for identity, selection, and operations without invasive changes to rendering or layout.
