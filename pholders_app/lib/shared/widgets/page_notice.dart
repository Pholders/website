import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


/// The teal the doctor and pharmacy screens are built in. The theme's
/// own primary is a blue used elsewhere in the app.
const _teal = Color(0xFF2EC4C4);

/// A page that has nothing on it, and says why.
///
/// Several routes used to render the bare words "To be implemented", which
/// tells a tester nothing: they cannot know whether they have found a defect,
/// a half-finished screen, or something deliberately left out of this phase.
/// Each of those is a different thing to do about it.
///
/// Where the work exists somewhere else, [goTo] points at it rather than
/// leaving the person at a dead end.
class PageNotice extends StatelessWidget {
  const PageNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.goToLabel,
    this.goTo,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? goToLabel;
  final String? goTo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 42, color: _teal),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2B2B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.55,
                    color: Color(0xFF6B8080),
                  ),
                ),
                if (goTo != null && goToLabel != null) ...[
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () => context.go(goTo!),
                    style: FilledButton.styleFrom(
                      backgroundColor: _teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Text(goToLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
