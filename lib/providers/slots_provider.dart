import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../core/failure.dart';
import '../data/booking_repository.dart';
import '../data/venue_repository.dart';
import '../models/slot.dart';
import 'view_state.dart';

/// Outcome of a tap-to-book, so the UI can show the right message.
enum BookOutcome { success, slotTaken, error }

/// Drives the venue-detail slot grid: holds the selected date, loads slots,
/// polls for live updates (bonus), and performs bookings.
class SlotsProvider extends ChangeNotifier {
  SlotsProvider(this._venues, this._bookings, this.venueId, this.openHour, this.closeHour);

  final VenueRepository _venues;
  final BookingRepository _bookings;
  final int venueId;
  final int openHour;
  final int closeHour;

  ViewState state = ViewState.idle;
  String? errorMessage;
  List<Slot> slots = [];
  DateTime selectedDate = DateTime.now();
  bool _disposed = false;

  Timer? _pollTimer;

  String get dateParam {
    final y = selectedDate.year.toString().padLeft(4, '0');
    final m = selectedDate.month.toString().padLeft(2, '0');
    final d = selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> setDate(DateTime date) async {
    selectedDate = DateTime(date.year, date.month, date.day);
    await load();
  }

  /// Full (re)load with the loading state — used on first open and date change.
  Future<void> load() async {
    state = ViewState.loading;
    errorMessage = null;
    _safeNotify();
    await _fetch(showLoading: true);
  }

  /// Silent refresh used by polling and after a booking — no loading flicker.
  Future<void> refresh() => _fetch(showLoading: false);

  Future<void> _fetch({required bool showLoading}) async {
    try {
      final result = await _venues.fetchSlots(venueId, dateParam);
      slots = result;
      state = result.isEmpty ? ViewState.empty : ViewState.success;
    } on Failure catch (f) {
      // Don't blow away a good grid on a transient poll failure.
      if (showLoading || slots.isEmpty) {
        state = ViewState.error;
        errorMessage = f.message;
      }
    }
    _safeNotify();
  }

  /// Poll the grid so a slot booked on another device flips to "booked" live.
  void startPolling() {
    _pollTimer ??= Timer.periodic(AppConfig.slotPollInterval, (_) => refresh());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Books [slot]. On 409 we refresh the grid so the slot shows as booked.
  Future<BookOutcome> book(Slot slot) async {
    try {
      await _bookings.createBooking(
        venueId: venueId,
        date: dateParam,
        startHour: slot.startHour,
      );
      await refresh();
      return BookOutcome.success;
    } on SlotTakenFailure {
      await refresh(); // someone else got it — reflect the new reality
      return BookOutcome.slotTaken;
    } on Failure catch (f) {
      errorMessage = f.message;
      return BookOutcome.error;
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    super.dispose();
  }
}
