import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../theme/app_colors.dart';

/// One look for every confirmation, error and info message (SRS BR-040).
///
/// Agreed with the team on 2026-11-21:
/// * errors open a dialog that stays until the user closes it, so nobody
///   misses one;
/// * routine success and info messages show as a toast for [toastDuration]
///   with an ✕ to close them sooner.
class AppFeedback {
  AppFeedback._();

  /// Long enough to read, per the team's request for 15-20 seconds.
  static const Duration toastDuration = Duration(seconds: 15);

  static const Color _errorColor = Color(0xFFB42318);

  /// A green-teal toast confirming something worked.
  static void success(BuildContext context, String message) =>
      _toast(context, message, Icons.check_circle_rounded, AppColors.activeTeal);

  /// A neutral toast for something the user should know but need not act on.
  static void info(BuildContext context, String message) => _toast(
      context, message, Icons.info_outline_rounded, AppColors.textPrimary);

  /// A dialog explaining what failed. It stays until closed.
  ///
  /// [error] may be an [ApiException], any other object, or a ready-made
  /// message; it is turned into plain language by [describe]. When [onRetry]
  /// is given the dialog offers "Try again".
  static Future<void> error(
    BuildContext context,
    Object error, {
    String title = 'That didn\'t work',
    VoidCallback? onRetry,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.error_outline_rounded,
            color: _errorColor, size: 32),
        title: Text(title, textAlign: TextAlign.center),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            describe(error),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onRetry();
              },
              child: const Text('Try again'),
            ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.activeTeal),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Plain-language text for a failure.
  ///
  /// Messages the backend writes for people ("Prescription already signed")
  /// are kept. Transport failures and server crashes get a sentence that says
  /// what to do, not a status code or exception dump.
  static String describe(Object error) {
    if (error is String) return error;
    if (error is ApiException) {
      switch (error.kind) {
        case ApiErrorKind.network:
          return 'We couldn\'t reach Pholders. Check your internet connection '
              'and try again.';
        case ApiErrorKind.timeout:
          return 'The server took too long to answer. It may be starting up, '
              'so try again in a moment.';
        case ApiErrorKind.badResponse:
        case ApiErrorKind.unknown:
          return _generic;
        case ApiErrorKind.http:
          final code = error.statusCode ?? 0;
          if (code == 401) {
            return 'Your session has ended. Sign in again to continue.';
          }
          if (code >= 500) return _generic;
          return error.message;
      }
    }
    return _generic;
  }

  static const String _generic =
      'Something went wrong on our side. Try again in a minute, and contact '
      'support if it keeps happening.';

  static void _toast(
    BuildContext context,
    String message,
    IconData icon,
    Color color,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final screen = MediaQuery.sizeOf(context).width;
    messenger
      // A new message replaces the old one rather than queueing behind 15s.
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        width: math.min(440, screen - 32),
        duration: toastDuration,
        showCloseIcon: true,
        closeIconColor: Colors.white,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white, height: 1.35)),
            ),
          ],
        ),
      ));
  }
}
