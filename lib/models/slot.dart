/// One hourly slot for a venue on a date, with availability status.
/// Generated server-side; the app never builds these itself.
class Slot {
  final int venueId;
  final String date; // yyyy-MM-dd
  final int startHour;
  final String startTime; // "HH:00"
  final String endTime;
  final String status; // 'available' | 'booked'
  final int? bookingId;

  const Slot({
    required this.venueId,
    required this.date,
    required this.startHour,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.bookingId,
  });

  bool get isAvailable => status == 'available';
  bool get isBooked => status == 'booked';

  /// "06:00 – 07:00"
  String get label => '$startTime – $endTime';

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
        venueId: json['venue_id'] as int,
        date: json['date'] as String,
        startHour: json['start_hour'] as int,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        status: json['status'] as String,
        bookingId: json['booking_id'] as int?,
      );
}
