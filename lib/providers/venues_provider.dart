import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../data/venue_repository.dart';
import '../models/venue.dart';
import 'view_state.dart';

/// Loads and holds the venue list for the home screen.
class VenuesProvider extends ChangeNotifier {
  VenuesProvider(this._repo);
  final VenueRepository _repo;

  ViewState state = ViewState.idle;
  String? errorMessage;
  List<Venue> venues = [];

  Future<void> load() async {
    state = ViewState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      venues = await _repo.fetchVenues();
      state = venues.isEmpty ? ViewState.empty : ViewState.success;
    } on Failure catch (f) {
      state = ViewState.error;
      errorMessage = f.message;
    }
    notifyListeners();
  }
}
