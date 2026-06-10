import '../core/api_client.dart';
import '../models/booking.dart';

/// Creates, lists and cancels bookings. A 409 surfaces as [SlotTakenFailure]
/// (thrown by ApiClient) so the booking flow can react gracefully.
class BookingRepository {
  BookingRepository(this._api);
  final ApiClient _api;

  Future<Booking> createBooking({
    required int venueId,
    required String date,
    required int startHour,
  }) async {
    final data = await _api.post('/bookings', body: {
      'venue_id': venueId,
      'date': date,
      'start_hour': startHour,
    }) as Map<String, dynamic>;
    // POST returns the raw booking row (no venue join); build a light model.
    return Booking(
      id: data['id'] as int,
      venueId: data['venue_id'] as int,
      venueName: '',
      sport: '',
      location: '',
      date: data['slot_date'] as String,
      startHour: data['start_hour'] as int,
      status: data['status'] as String,
    );
  }

  Future<List<Booking>> fetchUserBookings(int userId) async {
    final data = await _api.get('/users/$userId/bookings') as List<dynamic>;
    return data.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cancelBooking(int bookingId) async {
    await _api.delete('/bookings/$bookingId');
  }
}
