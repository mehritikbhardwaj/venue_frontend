/// Typed errors thrown by repositories so providers/UI can react by category
/// instead of parsing exception strings.
sealed class Failure implements Exception {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// The slot was booked by someone else (HTTP 409). The booking flow uses this
/// to show a graceful message and refresh the grid.
class SlotTakenFailure extends Failure {
  const SlotTakenFailure([super.message = 'That slot was just booked by someone else.']);
}

/// Any other 4xx/5xx with a server-provided message.
class ApiFailure extends Failure {
  final int statusCode;
  const ApiFailure(this.statusCode, super.message);
}

/// No connectivity / timeout / unexpected transport error.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Check your connection and try again.']);
}
