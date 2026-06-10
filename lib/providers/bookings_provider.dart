import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../data/booking_repository.dart';
import '../models/booking.dart';
import 'view_state.dart';

/// Loads the current user's bookings and cancels them ("My Bookings").
class BookingsProvider extends ChangeNotifier {
  BookingsProvider(this._repo);
  final BookingRepository _repo;

  ViewState state = ViewState.idle;
  String? errorMessage;
  List<Booking> bookings = [];
  int? cancellingId; // booking currently being cancelled (for per-row spinner)

  Future<void> load(int userId) async {
    state = ViewState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      bookings = await _repo.fetchUserBookings(userId);
      state = bookings.isEmpty ? ViewState.empty : ViewState.success;
    } on Failure catch (f) {
      state = ViewState.error;
      errorMessage = f.message;
    }
    notifyListeners();
  }

  /// Cancels a booking and reloads. Returns true on success.
  Future<bool> cancel(int bookingId, int userId) async {
    cancellingId = bookingId;
    notifyListeners();
    try {
      await _repo.cancelBooking(bookingId);
      await load(userId);
      return true;
    } on Failure catch (f) {
      errorMessage = f.message;
      cancellingId = null;
      notifyListeners();
      return false;
    } finally {
      cancellingId = null;
    }
  }
}
