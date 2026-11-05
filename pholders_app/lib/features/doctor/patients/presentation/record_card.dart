import 'package:flutter/material.dart';

/// The look shared by a patient's History, Documents and Vitals tabs, so the
/// three stay alike: a white card on a teal edge, a round icon, a title and
/// a grey line saying what the tab is for, an optional row under them (the
/// History filters), then the content.
///
/// Given a height, the card fills it and the content scrolls inside, under
/// the title; without one, the card grows with its content.
class RecordCard extends StatefulWidget {
  const RecordCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.toolbar,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// The content, below the title.
  final Widget child;

  /// Beside the title, on the right: the tab's main action.
  final Widget? trailing;

  /// Between the subtitle and the content, such as a row of filters.
  final Widget? toolbar;

  @override
  State<RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<RecordCard> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final fill = c.hasBoundedHeight && c.maxHeight >= 360;
      return Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: RecordColors.aqua,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 16, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: RecordColors.pale,
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(widget.icon, size: 19, color: RecordColors.ink),
                    ),
                    const SizedBox(width: 14),
                    Text(widget.title,
                        style: const TextStyle(
                            fontSize: 20, color: RecordColors.ink)),
                    const Spacer(),
                    if (widget.trailing != null) widget.trailing!,
                  ],
                ),
                const SizedBox(height: 12),
                Text(widget.subtitle,
                    style: const TextStyle(
                        fontSize: 16, color: RecordColors.label)),
                const SizedBox(height: 16),
                if (widget.toolbar != null) ...[
                  widget.toolbar!,
                  const SizedBox(height: 16),
                ],
                if (fill)
                  Expanded(
                    child: Scrollbar(
                      controller: _scroll,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        padding: const EdgeInsets.only(right: 16),
                        child: widget.child,
                      ),
                    ),
                  )
                else
                  widget.child,
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// The colours of [RecordCard] and what goes in it.
abstract final class RecordColors {
  static const aqua = Color(0xFF6DD0D8);
  static const darkTeal = Color(0xFF2E9FA5);
  static const pale = Color(0xFFDFF4F6);
  static const paleEdge = Color(0xFFCDEBEE);
  static const ink = Color(0xFF1A2B2B);
  static const label = Color(0xFF9AA5A6);
  static const muted = Color(0xFF6C6C6C);
}

/// The pale pill with a teal plus, for a card's main action.
class RecordAction extends StatelessWidget {
  const RecordAction({super.key, required this.label, required this.onTap});
  final String label;

  /// Null greys it out.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(3, 3, 18, 3),
          decoration: BoxDecoration(
            color: RecordColors.pale,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: RecordColors.darkTeal,
                child: Icon(Icons.add, size: 22, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: RecordColors.darkTeal)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pale teal tile, as the History timeline's cards.
class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: RecordColors.pale,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RecordColors.paleEdge),
      ),
      child: child,
    );
  }
}

/// A spinner, or a grey line with an optional action, in place of content.
class RecordMessage extends StatelessWidget {
  const RecordMessage({super.key, this.text, this.action});

  /// Null shows a spinner.
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    if (text == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: RecordColors.aqua),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text!,
            style: const TextStyle(
                fontSize: 13, height: 1.5, color: RecordColors.label)),
        if (action != null) ...[const SizedBox(height: 8), action!],
      ],
    );
  }
}
