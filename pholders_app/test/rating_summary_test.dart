import 'package:flutter_test/flutter_test.dart';

import 'package:pholders_app/features/doctor/reviews/data/models/rating_summary.dart';

void main() {
  group('RatingSummary', () {
    test('reads the summary payload, distribution included', () {
      final summary = RatingSummary.fromJson({
        'doctorId': 3,
        'averageRating': 4.6,
        'totalReviews': 17,
        'ratingDistribution': [
          {'stars': 5, 'count': 12},
          {'stars': 4, 'count': 3},
          {'stars': 1, 'count': 2},
        ],
      });

      expect(summary.averageRating, 4.6);
      expect(summary.totalReviews, 17);
      expect(summary.distribution[5], 12);
      expect(summary.averageLabel, '4.6');
      expect(summary.filledStars, 5);
      expect(summary.hasReviews, isTrue);
    });

    test('a doctor with no reviews is not a doctor with a bad score', () {
      final summary = RatingSummary.fromJson({
        'averageRating': 0,
        'totalReviews': 0,
        'ratingDistribution': [],
      });

      expect(summary.hasReviews, isFalse);
      expect(summary.averageLabel, '—',
          reason: '0.0 out of 5 would read as terrible, not as unrated');
      expect(summary.filledStars, 0);
    });

    test('copes with the numbers arriving as strings', () {
      // The backend parses these itself, but other endpoints here return
      // numbers as strings, so the model should not assume.
      final summary = RatingSummary.fromJson({
        'averageRating': '3.4',
        'totalReviews': '9',
        'ratingDistribution': [
          {'stars': '3', 'count': '9'},
        ],
      });

      expect(summary.averageRating, 3.4);
      expect(summary.totalReviews, 9);
      expect(summary.distribution[3], 9);
    });

    test('rounds to whole stars for the icon row', () {
      expect(
        RatingSummary.fromJson({'averageRating': 4.4, 'totalReviews': 2})
            .filledStars,
        4,
      );
      expect(
        RatingSummary.fromJson({'averageRating': 4.5, 'totalReviews': 2})
            .filledStars,
        5,
      );
    });

    test('never asks for more than five stars', () {
      expect(
        RatingSummary.fromJson({'averageRating': 7, 'totalReviews': 1})
            .filledStars,
        5,
      );
    });

    test('a missing distribution is empty, not a crash', () {
      final summary =
          RatingSummary.fromJson({'averageRating': 5, 'totalReviews': 1});
      expect(summary.distribution, isEmpty);
    });
  });
}
