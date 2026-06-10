# QuickSlot (Flutter app)

QuickSlot lets you book sports slots (badminton courts and turf grounds). You log
in with your mobile number, browse venues, pick a date, see which hourly slots are
free, and book one. The core rule the whole thing is built around: the same slot
can't be booked twice.

Demo video: https://drive.google.com/file/d/1XfqAvtvzvQH9DuancTwhB0CpkkxDD1jU/view?usp=drive_link

State management is Provider, navigation is go_router. The backend (Node + Express
+ Postgres) is deployed at https://venuebackend.vercel.app and its code lives at
https://github.com/mehritikbhardwaj/venue_backend.

## Running it

```bash
flutter pub get
flutter run
```

By default the app talks to the deployed backend, so it works on a real phone or a
simulator without any extra setup. To run against a local backend instead, pass the
base URL:

```bash
# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:3000
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Tests: `flutter test`.

## How the code is organised

The dependency direction is one way: UI talks to providers, providers talk to
repositories, repositories talk to the ApiClient, and the ApiClient talks to the
backend. Nothing skips a layer and widgets never make HTTP calls or parse JSON.

```
lib/
  core/      ApiClient (the one http wrapper), config, theme, failure, session_store
  models/    User, Venue, Slot, Booking
  data/      AuthRepository, VenueRepository, BookingRepository
  providers/ Session, Venues, Slots, Bookings  (all ChangeNotifier)
  screens/   splash, login, complete_profile, venues, venue_detail, my_bookings
  widgets/   state views, slot tile, brand bits, OTP sheet
  router.dart
```

A few specifics worth calling out:

- `ApiClient` is the only thing that knows the base URL. It attaches the
  `X-User-Id` header and turns HTTP/transport errors into a typed `Failure`
  (`SlotTakenFailure`, `ApiFailure`, `NetworkFailure`) so the rest of the app
  never sees a raw `http.Response`.
- Every provider exposes a `ViewState` (idle / loading / success / empty / error).
  Each screen switches on it, which is why loading, error and empty states are
  handled the same way everywhere.
- The session (id, name, mobile) is saved with SharedPreferences, so you stay
  logged in across restarts. The splash screen restores it and decides where to go.

## Login (mobile + OTP)

1. Enter a 10-digit mobile number. The app calls `POST /auth/request-otp`; the
   backend creates the user if it's new and returns a 6-digit OTP in the response.
   There's no real SMS provider, so for the demo the OTP comes back in the API and
   is shown on the verify sheet.
2. Enter the OTP. `POST /auth/verify-otp` checks it and, on success, the user id is
   set as `X-User-Id` for everything that follows.
3. If it's a brand new user, they're asked for their name once, which is saved with
   `PATCH /users/:id`. Returning users skip straight to the venue list.

## How double-booking is handled

The guarantee is enforced in the database with a partial unique index, so only one
booking can win for a given (venue, date, hour). On the app side, if `POST /bookings`
comes back as 409 the repository throws `SlotTakenFailure`. The booking flow catches
that, tells the user the slot was just taken, and reloads the grid so it immediately
shows as booked. The grid also re-fetches every few seconds, so if someone books a
slot on another phone it flips to "booked" on yours without a restart.

## Why Provider

It's small and there's nothing hidden: a screen reads its provider, calls a method,
and `notifyListeners()` triggers the rebuild. That makes it easy to walk through and
explain line by line, which matters more here than the extra structure Bloc or
Riverpod would bring to an app this size.

## What I attempted from the bonus list

- Live slot updates by polling, so a slot flips to booked on another device.
- Unit tests for the booking logic in `test/booking_logic_test.dart` (the success,
  409-already-taken, and generic-error paths, plus slot parsing).

I also added persistent login on top of the brief, since it made the demo smoother.

## What I cut, and why

- No offline cache. Every screen reads live data and polling keeps it fresh. An
  offline cache for My Bookings was on the bonus list but I put live updates and
  tests ahead of it.
- No real SMS. The OTP is returned by the API and shown in the app. Wiring a
  provider like Twilio wasn't worth the time for a demo.
- Venue detail gets its `Venue` through go_router's `extra` rather than a
  `/venues/:id` route. Fine for navigating inside the app; a real app would use an
  id so the route is deep-linkable.

## With one more day

- Offline read cache for My Bookings.
- Swap polling for a websocket so updates are instant instead of every few seconds.
- Filter slots by time of day, and a richer venue page (photos, pricing).
- A widget/integration test for the full book → conflict → refresh path.

## Where I used AI, and what it got wrong

I used AI to scaffold the layered structure, the providers, and the screens, then
went through and adjusted things by hand. The one bug it introduced that I had to
catch: the backend was returning slot dates as full UTC timestamps. In IST that
pushed each date back by a day, so the dates coming back didn't line up with the
date I was sending in the query. I spotted it in the My Bookings response and fixed
it on the server by parsing Postgres `DATE` columns as plain `yyyy-MM-dd` strings,
which is what the app sends and expects.
