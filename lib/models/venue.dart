/// A bookable venue (badminton court / turf).
class Venue {
  final int id;
  final String name;
  final String sport;
  final String location;
  final int openHour;
  final int closeHour;

  const Venue({
    required this.id,
    required this.name,
    required this.sport,
    required this.location,
    required this.openHour,
    required this.closeHour,
  });

  factory Venue.fromJson(Map<String, dynamic> json) => Venue(
        id: json['id'] as int,
        name: json['name'] as String,
        sport: json['sport'] as String,
        location: json['location'] as String,
        openHour: json['open_hour'] as int? ?? 6,
        closeHour: json['close_hour'] as int? ?? 22,
      );
}
