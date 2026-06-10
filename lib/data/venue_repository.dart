import '../core/api_client.dart';
import '../models/slot.dart';
import '../models/venue.dart';

/// Reads venues and their slot grids. Maps JSON -> models; lets typed
/// [Failure]s from [ApiClient] propagate to the provider.
class VenueRepository {
  VenueRepository(this._api);
  final ApiClient _api;

  Future<List<Venue>> fetchVenues() async {
    final data = await _api.get('/venues') as List<dynamic>;
    return data.map((e) => Venue.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Slot>> fetchSlots(int venueId, String date) async {
    final data = await _api.get('/venues/$venueId/slots', query: {'date': date})
        as Map<String, dynamic>;
    final slots = data['slots'] as List<dynamic>;
    return slots.map((e) => Slot.fromJson(e as Map<String, dynamic>)).toList();
  }
}
