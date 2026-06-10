/// A user's booking, enriched with venue info for the "My Bookings" list.
class Booking {
  final int id;
  final int venueId;
  final String venueName;
  final String sport;
  final String location;
  final String date; // yyyy-MM-dd
  final int startHour;
  final String status; // 'booked' | 'cancelled'

  const Booking({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.sport,
    required this.location,
    required this.date,
    required this.startHour,
    required this.status,
  });

  bool get isActive => status == 'booked';

  /// When this booking's slot starts, from its date + hour.
  DateTime get startsAt => DateTime.parse(date).add(Duration(hours: startHour));

  /// True once the slot's start time has passed.
  bool get isPast => startsAt.isBefore(DateTime.now());

  /// Upcoming = still active and not yet started. Everything else (already
  /// started/finished, or cancelled) is treated as past for the tabs.
  bool get isUpcoming => isActive && !isPast;

  /// "14:00 – 15:00"
  String get timeLabel {
    String hh(int h) => '${h.toString().padLeft(2, '0')}:00';
    return '${hh(startHour)} – ${hh(startHour + 1)}';
  }

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as int,
        venueId: json['venue_id'] as int,
        venueName: json['venue_name'] as String,
        sport: json['sport'] as String,
        location: json['location'] as String,
        date: json['slot_date'] as String,
        startHour: json['start_hour'] as int,
        status: json['status'] as String,
      );
}
