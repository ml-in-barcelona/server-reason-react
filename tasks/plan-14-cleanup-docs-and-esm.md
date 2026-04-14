# Cleanup: update protocol docs and fix esbuild ESM/CJS issue

**Priority**: Lower
**Independent of other plans** (can be done anytime)
**Origin**: Layer 2.3 and Layer 5.1 from plan-03-rethink-server-actions-architecture.md

## Tasks

### 2.3 Clean up the unsupported `$`-prefixes comment block

**File**: `packages/reactDom/` — the large comment block around line 1169-1200 that lists all supported/unsupported `$`-prefixes.

**Current**: Some prefixes listed as unsupported are now supported (`$T`, `$B`, etc.). The documentation is stale.

- [ ] Locate the comment block listing `$`-prefix support status
- [ ] Update it to reflect current implementation status (mark `$T`, `$B` as supported, update any others)
- [ ] Remove or update any outdated TODOs in the comment

### 5.1 Server function manifest uses `require()` (CJS) in ESM context

**File**: `packages/esbuild-plugin/extract_client_components.ml:65`

**Current**:
```javascript
window.__server_functions_manifest_map["<id>"] = require("<path>").<export>
```

The generated bootstrap code uses `require()` for server functions but `import()` for client components. In a pure ESM environment, `require()` may not be available.

- [ ] Evaluate whether the esbuild bundle output is CJS or ESM (check esbuild config in the demo)
- [ ] If ESM: switch to dynamic `import()` for server functions, or use a sync import that esbuild resolves at bundle time
- [ ] If CJS: document why `require()` is acceptable and add a comment
- [ ] Ensure consistency: either both client components and server functions use the same module loading strategy, or document why they differ

## Verification

- [ ] Run `make build` — both native and Melange compilation must succeed
- [ ] Run `make test` — all existing tests pass
- [ ] Run `make demo-serve` — demo app builds and serves without errors
- [ ] If the esbuild manifest generation changed:
  - Inspect the generated `bootstrap.js` output
  - Verify server functions are correctly loaded and callable from the client
  - Test a server action end-to-end in the demo
- [ ] For the comment update: visual inspection only (no runtime impact)

## Dependencies

- None — fully independent cleanup work
