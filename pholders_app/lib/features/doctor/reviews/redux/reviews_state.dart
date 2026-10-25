import 'package:equatable/equatable.dart';

import '../data/models/rating_summary.dart';

/// The reviews slice of the Redux store.
class ReviewsState extends Equatable {
  const ReviewsState({
    this.summary,
    this.isLoading = false,
    this.errorMessage,
  });

  factory ReviewsState.initial() => const ReviewsState();

  /// Null until the first fetch resolves. A summary with zero reviews is a
  /// real answer and must not be confused with this.
  final RatingSummary? summary;
  final bool isLoading;
  final String? errorMessage;

  ReviewsState copyWith({
    RatingSummary? summary,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReviewsState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [summary, isLoading, errorMessage];
}
