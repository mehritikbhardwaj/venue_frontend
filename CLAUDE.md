# QuickSlot Flutter App — AI / Engineering Rules

Binding rules for this repo. Follow them; don't drift.

## Architecture (layered, unidirectional)

```
UI (screens/widgets)  →  providers  →  repositories  →  ApiClient  →  backend
```

- **`core/`** — `ApiClient` (single http wrapper), `config` (base URL via
  `--dart-define`), `theme`, `failure` (typed errors). No feature logic.
- **`models/`** — immutable data classes with `fromJson`. No business logic, no
  formatting beyond derived getters.
- **`data/repositories/`** — translate API calls into model objects and throw
  typed `Failure`s. The ONLY layer that knows about endpoints/JSON shapes besides
  models. Never import Flutter widgets.
- **`providers/`** — `ChangeNotifier`s holding view state via an explicit
  `ViewState { idle, loading, success, error, empty }` enum. All async/business
  logic lives here. Providers call repositories, never `ApiClient` directly.
- **`screens/` + `widgets/`** — presentation only. Read state from providers via
  `context.watch` / `Consumer`, fire actions via `context.read().method()`.
  **No business logic, no HTTP, no JSON in widgets.** A widget may not call a
  repository or ApiClient directly.
- **`router.dart`** — all navigation via `go_router`. No `Navigator.push` with
  raw `MaterialPageRoute` in screens.

## State management — Provider (justification for defense)

- Chosen for its small surface and explicit `ChangeNotifier` lifecycle: easy to
  explain line-by-line, no codegen, no magic. Each screen's state is one provider;
  `notifyListeners()` is the only redraw trigger.
- Every data-loading provider exposes `state` (the `ViewState` enum), the loaded
  `data`, and an `errorMessage`. UI switches on `state` to render
  loading / error / empty / content — this is **required on every screen**.

## API integration rules

- All requests go through `ApiClient`, which sets the base URL and injects the
  `X-User-Id` header from the current session.
- Repositories map HTTP status → outcome:
  - 2xx → parse model
  - 409 → `SlotTakenFailure` (booking flow shows graceful message + refreshes grid)
  - 4xx → `ApiFailure` with server message
  - network/timeout → `NetworkFailure`
- Never let a raw `http.Response` or `Exception` reach a widget. Repositories
  throw `Failure`; providers catch and set `state = error`.
- Dates sent to the API are `yyyy-MM-dd` strings (use `intl`/`DateFormat`),
  matching the backend contract exactly.

## Conventions

- Immutable models, `const` constructors where possible.
- One widget file per screen; shared UI (slot tile, state views) in `widgets/`.
- No `print` in committed code; surface errors through provider state.
- Backend base URL is configurable: defaults to the deployed
  `https://venuebackend.vercel.app`, overridable with
  `--dart-define=API_BASE_URL=...`.
