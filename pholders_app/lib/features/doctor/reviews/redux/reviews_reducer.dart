import '../../../../core/auth/auth_actions.dart';
import 'reviews_actions.dart';
import 'reviews_state.dart';

ReviewsState reviewsReducer(ReviewsState state, dynamic action) {
  if (action is LoadRatingSummaryAction) {
    return state.copyWith(isLoading: true, clearError: true);
  }

  if (action is RatingSummaryLoadedAction) {
    return state.copyWith(summary: action.summary, isLoading: false);
  }

  if (action is RatingSummaryFailedAction) {
    return state.copyWith(isLoading: false, errorMessage: action.errorMessage);
  }

  // One doctor's rating must never be shown to the next one who signs in.
  if (action is LogoutAction || action is SessionExpiredAction) {
    return ReviewsState.initial();
  }

  return state;
}
