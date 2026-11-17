import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/network/api_exception.dart';
import '../data/reviews_repository.dart';
import 'reviews_actions.dart';

/// Middleware performing the review network calls.
List<Middleware<AppState>> createReviewsMiddleware({
  required ReviewsRepository repository,
}) {
  Future<void> loadSummary(
    Store<AppState> store,
    LoadRatingSummaryAction action,
  ) async {
    try {
      final summary = await repository.fetchSummary(action.doctorId);
      store.dispatch(RatingSummaryLoadedAction(summary: summary));
    } on ApiException catch (e) {
      store.dispatch(RatingSummaryFailedAction(errorMessage: e.message));
    }
  }

  void middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
    next(action);
    if (action is LoadRatingSummaryAction) {
      loadSummary(store, action);
    }
  }

  return [middleware];
}
