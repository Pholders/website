import '../../../../core/network/api_client.dart';
import 'models/rating_summary.dart';

/// Patient reviews of a doctor.
///
/// These routes carry no role guard — a patient browsing doctors reads the
/// same ones — so the doctor passes their own id rather than the API
/// inferring it from the token.
class ReviewsRepository {
  const ReviewsRepository(this._api);

  final ApiClient _api;

  /// The doctor's average rating and how the stars are spread.
  Future<RatingSummary> fetchSummary(int doctorId) async {
    final data = await _api.get(
      '/users/appointments/doctors/$doctorId/reviews/summary',
    );
    return RatingSummary.fromJson(data);
  }
}
