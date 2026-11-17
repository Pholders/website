import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A page's [body] with a [header] floating over its top that slides away
/// while the page scrolls down and comes back as soon as it scrolls up.
///
/// The header is always shown near the top of the page. Only the page's
/// own vertical scrolling moves it: sideways rows and scroll areas nested
/// inside the page do not, and nor does a jitter of a few pixels.
class HideOnScrollHeader extends StatefulWidget {
  const HideOnScrollHeader({
    super.key,
    required this.body,
    required this.header,
    this.top = 36,
    this.left = 0,
    this.right = 0,
  });

  /// The scrolling page, under the header.
  final Widget body;

  /// What floats over it: the navbar.
  final Widget header;

  /// Where the header sits.
  final double top;
  final double left;
  final double right;

  /// Within this far of the top the header always shows.
  static const revealZone = 80.0;

  /// How far the page must move one way before the header follows.
  static const threshold = 12.0;

  @override
  State<HideOnScrollHeader> createState() => _HideOnScrollHeaderState();
}

class _HideOnScrollHeaderState extends State<HideOnScrollHeader> {
  bool _shown = true;

  /// Movement in the current direction since the header last changed.
  double _travel = 0;

  bool _onScroll(ScrollNotification n) {
    // The page's own scroll view, not a row or panel inside it.
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;

    if (n.metrics.pixels <= HideOnScrollHeader.revealZone) {
      _travel = 0;
      _set(true);
      return false;
    }

    double? delta;
    if (n is ScrollUpdateNotification) {
      delta = n.scrollDelta;
    } else if (n is UserScrollNotification) {
      // A fling's direction, before its updates arrive.
      if (n.direction == ScrollDirection.reverse) delta = 0.001;
      if (n.direction == ScrollDirection.forward) delta = -0.001;
    }
    if (delta == null || delta == 0) return false;

    // Down hides, up shows; a change of direction starts the count again.
    if ((delta > 0) != (_travel > 0)) _travel = 0;
    _travel += delta;
    if (_travel > HideOnScrollHeader.threshold) _set(false);
    if (_travel < -HideOnScrollHeader.threshold) _set(true);
    return false;
  }

  void _set(bool shown) {
    if (_shown == shown) return;
    setState(() => _shown = shown);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.body,
        ),
        Positioned(
          top: widget.top,
          left: widget.left,
          right: widget.right,
          child: IgnorePointer(
            // A hidden header must not catch clicks meant for the page.
            ignoring: !_shown,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              // Up past the top of the window, with its gap and shadow.
              offset: Offset(0, _shown ? 0 : -1.8),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _shown ? 1 : 0,
                child: widget.header,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
