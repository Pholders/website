import '../data/models/rating_summary.dart';

/// Dispatched to load the signed-in doctor's rating.
class LoadRatingSummaryAction {
  const LoadRatingSummaryAction({required this.doctorId});
  final int doctorId;
}

/// Dispatched when the rating arrives.
class RatingSummaryLoadedAction {
  const RatingSummaryLoadedAction({required this.summary});
  final RatingSummary summary;
}

/// Dispatched when it cannot be loaded.
class RatingSummaryFailedAction {
  const RatingSummaryFailedAction({required this.errorMessage});
  final String errorMessage;
}
