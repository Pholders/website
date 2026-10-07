import 'package:equatable/equatable.dart';

/// How patients have rated the signed-in doctor.
///
/// Shape comes from
/// `GET /users/appointments/doctors/:doctorId/reviews/summary`.
class RatingSummary extends Equatable {
  const RatingSummary({
    required this.averageRating,
    required this.totalReviews,
    this.distribution = const {},
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['ratingDistribution'];
    final distribution = <int, int>{};
    if (raw is List) {
      for (final entry in raw.whereType<Map<String, dynamic>>()) {
        final stars = _asInt(entry['stars']);
        final count = _asInt(entry['count']);
        if (stars != null && count != null) distribution[stars] = count;
      }
    }

    return RatingSummary(
      averageRating: _asDouble(json['averageRating']) ?? 0,
      totalReviews: _asInt(json['totalReviews']) ?? 0,
      distribution: distribution,
    );
  }

  /// Zero when nobody has reviewed yet, which is not the same as a bad score.
  final double averageRating;
  final int totalReviews;

  /// Stars (1-5) to how many gave them.
  final Map<int, int> distribution;

  bool get hasReviews => totalReviews > 0;

  /// "4.6", or an em dash when there is nothing to average.
  String get averageLabel =>
      hasReviews ? averageRating.toStringAsFixed(1) : '—';

  /// Whole stars, for the row of icons.
  int get filledStars => averageRating.round().clamp(0, 5);

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  static double? _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  @override
  List<Object?> get props => [averageRating, totalReviews, distribution];
}
