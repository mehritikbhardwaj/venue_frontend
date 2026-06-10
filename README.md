# QuickSlot — Flutter App

A mini app for booking sports slots (badminton courts / turf grounds). Browse
venues, view hourly slots for a date, and book — with the guarantee that a slot
can never be double-booked.

- **State management:** Provider (`ChangeNotifier`)
- **Navigation:** go_router
- **Backend:** Node + Express + Postgres, live at `https://venuebackend.vercel.app`
  ([server repo](https://github.com/mehritikbhardwaj/venue_backend))

## Setup

```bash
flutter pub get
flutter run            # uses the deployed backend by default — works on any device
```

Point at a local backend instead:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000      # iOS simulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000       # Android emulator
```

Run the tests: `flutter test`.

## Architecture (one paragraph)

Strictly layered, one direction of dependency:
**UI → providers → repositories → ApiClient → backend.** Widgets are presentation
only — they read state from providers and fire actions; there is no HTTP, JSON, or
business logic inside any widget. `ApiClient` is the single HTTP wrapper (injects
the `X-User-Id` header, maps transport/status errors to a typed `Failure`).
Repositories turn API calls into models. Providers (`ChangeNotifier`) hold an
explicit `ViewState { idle, loading, success, empty, error }` that every screen
switches on, so loading / error / empty states are handled everywhere by
construction.

```
lib/
  core/      api_client, config, theme, failure
  models/    User, Venue, Slot, Booking (immutable, fromJson)
  data/      VenueRepository, BookingRepository, UserRepository
  providers/ Session, Venues, Slots (+ polling), Bookings  — all ChangeNotifier
  screens/   login (user-select), venues, venue_detail (grid), my_bookings
  widgets/   LoadingView / ErrorView / EmptyView, SlotTile
  router.dart  go_router config
```

### Why Provider (defense)

Small, explicit, no codegen, no magic — easy to explain line-by-line. Each screen
maps to one provider; `notifyListeners()` is the only redraw trigger. The
`ViewState` enum makes the loading/error/empty/content contract uniform and
testable. For an app this size, Bloc/Riverpod would add ceremony without benefit.

### Double-booking, handled gracefully

The backend enforces single-winner at the DB (partial unique index). On the
client, a `POST /bookings` that returns **409** is mapped to `SlotTakenFailure`;
the booking flow catches it, shows a clear "that slot was just booked by someone
else" message, and **refreshes the grid** so the slot immediately shows as booked.
The venue-detail grid also **polls every 4s**, so a slot booked on another device
flips to "booked" without a restart (bonus: live updates).

## Bonus attempted

- **Live slot updates** via polling (slot flips to booked on another phone).
- **Unit tests** for the booking logic (`test/booking_logic_test.dart`):
  success / 409-slot-taken / generic-error paths + model parsing.

## What I cut and why

- **No persistent login / secure storage** — user select is a single tap (brief
  says keep auth light). The selected id is held in memory as `X-User-Id`.
- **No offline cache** — every screen reads live; polling keeps slots fresh.
  An offline read cache for My Bookings was a listed bonus I deprioritised behind
  live updates + tests.
- **Date passed via `extra`** in go_router (not a deep-linkable id) — fine for the
  in-app flow; a production app would use `/venues/:id`.

## What I'd do with one more day

- Offline read cache for My Bookings (bonus #2 I skipped).
- WebSocket push instead of polling.
- Filter slots by time of day; richer venue detail (images, pricing).
- Widget/integration test for the full book→conflict→refresh flow.

## AI usage note

AI scaffolded the layered structure, providers, and screens. **One thing it got
wrong that I caught:** the backend initially returned slot dates as full UTC
timestamps, which (under IST) shifted the day backward and broke date matching
between the grid and the API. I diagnosed it from the `My Bookings` payload and
fixed it server-side with a Postgres `DATE` type parser so dates stay plain
`yyyy-MM-dd`, matching the client's `date` query param exactly.
