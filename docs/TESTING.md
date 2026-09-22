# SmritiSetu — Quality Assurance & Testing Strategy

## 1. Testing Pyramid

SmritiSetu enforces a rigorous test pyramid ensuring rock-solid stability before any production deployment:

```
        / \
       /   \     E2E / Integration Tests (Flutter Driver, Cypress/Supertest)
      / ----\
     /       \   Widget / Component Tests (Accessibility semantics, 56px touch bounds)
    / --------\
   /           \ Unit Tests (Adaptive Difficulty, SQLite Schemas, Sync Engine, Token Vault)
  /-------------\
```

---

## 2. Unit Testing Matrix

### 2.1 Adaptive Difficulty Engine (`test/adaptive_difficulty_test.dart`)
- `test_promotion_threshold`: Verifies level increase when rolling score $\ge 0.82$ across 2 sessions.
- `test_single_error_resilience`: Verifies that an isolated mis-tap does not trigger immediate demotion.
- `test_demotion_on_prolonged_struggle`: Verifies level decrease when score $< 0.45$ over consecutive sessions.
- `test_boundary_conditions`: Asserts strict clamping within integer range $[1, 5]$.

### 2.2 SQLite Data Layer & Sync Queue (`test/database_test.dart`)
- `test_normalized_foreign_keys`: Confirms cascade deletion when a parent patient is removed.
- `test_sync_queue_enqueue_on_game_finish`: Verifies that a game completion creates both a local record and a pending sync queue item.
- `test_idempotent_session_insert`: Verifies that duplicate inserts with the same session UUID do not throw fatal exceptions.

### 2.3 Localization & RTL Directionality (`test/localization_test.dart`)
- `test_all_keys_present_in_regional_bundles`: Verifies that all keys in `en.json` exist in `as.json`, `mni.json`, and `hi.json`.
- `test_arabic_rtl_layout_direction`: Verifies that selecting Arabic (`ar`) switches `Directionality` to RTL.

---

## 3. Accessibility & UX Compliance Testing

- **Font Size Verification:** Asserts that body text widgets use $\ge 20\,\text{logical pixels}$.
- **Touch Target Verification:** Asserts that every `ElevatedButton`, `IconButton`, and game tile has minimum dimensions of $56 \times 56\,\text{logical pixels}$.
- **Semantics & Screen Readers:** Verifies that all interactive icons provide non-null `Semantics(label: ...)` annotations.
- **Contrast Ratio:** Validates WCAG AAA compliance ($> 7:1$ contrast ratio) across all color tokens in light and high-contrast dark modes.
