/// User-facing messages for known backend error `code` values.
///
/// The backend error envelope is `{ success: false, message, code? }`.
/// Match on [code], not [message], because message text can change over time.
/// Extend this map as the backend introduces new codes.
const Map<String, String> apiErrorCodeMessages = {
  'INVALID_TRANSITION': "This order can't move to that status yet.",
  'ALREADY_DISPENSED': 'These order items have already been dispensed.',
  'CLAIM_REQUIRED': 'Submit the medical-aid claim before proceeding.',
  'CANCEL_NOT_ALLOWED': "This order can't be cancelled anymore.",
};

/// Returns the friendly message for [code], or [fallback] (or a generic
/// message) if [code] is null or unknown.
String messageForApiCode(String? code, {String? fallback}) {
  if (code != null) {
    final mapped = apiErrorCodeMessages[code];
    if (mapped != null) return mapped;
  }
  return fallback ?? 'Something went wrong. Please try again.';
}
