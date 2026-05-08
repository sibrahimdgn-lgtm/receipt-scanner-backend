# Test Strategy

## Goal

Verify behavior with the smallest meaningful proof first, then widen only when the changed surface needs it.

## Default Verification Order

1. Syntax / compile sanity
2. Focused unit or widget tests
3. Local API smoke checks
4. Web build
5. Real Gemini scan only when explicitly needed

## Gemini Cost Rule

Real Gemini calls are not part of the default verification lane.

Prefer:
- unit tests for prompt/schema generation
- upload filter smoke tests that fail before Gemini
- import-based smoke tests that do not invoke Gemini
- health, auth, and history/summary checks

Use a real Gemini receipt scan only when:
- the user asks for a real end-to-end proof
- the bug only reproduces on the live model path
- lower-cost verification cannot prove the changed behavior

If a real Gemini call is made:
- keep it to the minimum number of requests
- use one representative file
- record that choice in `LOCAL_RUN_PLAN.md`

## Local Commands

- Node tests:
  - `node --test test/*.test.js`
- Flutter tests:
  - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
- Flutter web build:
  - `/Users/ibrahimdogan/development/flutter/bin/flutter build web --release`
- API health:
  - `curl http://127.0.0.1:3000/api/health`

## Cleanup

- Remove temp upload files created during smoke tests
- Keep local DB state intentional
- Document any persistent test accounts or receipts in `LOCAL_RUN_PLAN.md`
