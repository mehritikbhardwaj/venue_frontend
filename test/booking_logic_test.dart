import 'package:flutter_test/flutter_test.dart';
import 'package:quickslot/core/api_client.dart';
import 'package:quickslot/core/failure.dart';
import 'package:quickslot/data/booking_repository.dart';
import 'package:quickslot/data/venue_repository.dart';
import 'package:quickslot/models/booking.dart';
import 'package:quickslot/models/slot.dart';
import 'package:quickslot/providers/slots_provider.dart';
import 'package:quickslot/providers/view_state.dart';

/// Fake repos so we can drive SlotsProvider.book without real HTTP.
class FakeVenueRepo extends VenueRepository {
  FakeVenueRepo() : super(ApiClient());
  List<Slot> slots = const [];
  @override
  Future<List<Slot>> fetchSlots(int venueId, String date) async => slots;
}

class FakeBookingRepo extends BookingRepository {
  FakeBookingRepo() : super(ApiClient());
  Object? throwOnCreate; // set to a Failure to simulate the backend rejecting

  @override
  Future<Booking> createBooking({
    required int venueId,
    required String date,
    required int startHour,
  }) async {
    if (throwOnCreate != null) throw throwOnCreate!;
    return Booking(
      id: 1,
      venueId: venueId,
      venueName: '',
      sport: '',
      location: '',
      date: date,
      startHour: startHour,
      status: 'booked',
    );
  }
}

Slot availableSlot(int hour) => Slot(
      venueId: 1,
      date: '2030-01-01',
      startHour: hour,
      startTime: '${hour.toString().padLeft(2, '0')}:00',
      endTime: '${(hour + 1).toString().padLeft(2, '0')}:00',
      status: 'available',
    );

void main() {
  group('Slot model', () {
    test('parses JSON and derives availability + label', () {
      final slot = Slot.fromJson({
        'venue_id': 1,
        'date': '2030-01-01',
        'start_hour': 6,
        'start_time': '06:00',
        'end_time': '07:00',
        'status': 'available',
        'booking_id': null,
      });
      expect(slot.isAvailable, isTrue);
      expect(slot.isBooked, isFalse);
      expect(slot.label, '06:00 – 07:00');
    });
  });

  group('SlotsProvider.book (booking logic)', () {
    late FakeVenueRepo venues;
    late FakeBookingRepo bookings;
    late SlotsProvider provider;

    setUp(() {
      venues = FakeVenueRepo()..slots = [availableSlot(9)];
      bookings = FakeBookingRepo();
      provider = SlotsProvider(venues, bookings, 1, 6, 22);
    });

    test('returns success when the slot is free', () async {
      final outcome = await provider.book(availableSlot(9));
      expect(outcome, BookOutcome.success);
    });

    test('returns slotTaken on a 409 (SlotTakenFailure) and refreshes grid', () async {
      bookings.throwOnCreate = const SlotTakenFailure();
      // After the race, the backend now reports the slot as booked.
      venues.slots = [
        Slot(
          venueId: 1,
          date: '2030-01-01',
          startHour: 9,
          startTime: '09:00',
          endTime: '10:00',
          status: 'booked',
          bookingId: 42,
        ),
      ];

      final outcome = await provider.book(availableSlot(9));

      expect(outcome, BookOutcome.slotTaken);
      // Grid was refreshed: the slot now shows as booked.
      expect(provider.slots.single.isBooked, isTrue);
      expect(provider.state, ViewState.success);
    });

    test('returns error and surfaces a message on a generic failure', () async {
      bookings.throwOnCreate = const NetworkFailure('offline');
      final outcome = await provider.book(availableSlot(9));
      expect(outcome, BookOutcome.error);
      expect(provider.errorMessage, 'offline');
    });
  });
}
