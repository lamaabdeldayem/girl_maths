// lib/core/responsive.dart
//
// Breakpoint strategy from Lecture 4 (LayoutBuilder + MediaQuery):
//   compact  : width < 600  (phone portrait)
//   medium   : 600 – 1023   (phone landscape, small tablets)
//   expanded : >= 1024      (tablets landscape, desktop, web)
import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded }

class Breakpoints {
  static const double medium = 600;
  static const double expanded = 1024;

  static ScreenSize of(double width) {
    if (width >= expanded) return ScreenSize.expanded;
    if (width >= medium) return ScreenSize.medium;
    return ScreenSize.compact;
  }
}

extension ResponsiveX on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  ScreenSize get screenClass => Breakpoints.of(screenSize.width);
  bool get isCompact => screenClass == ScreenSize.compact;
  bool get isExpanded => screenClass == ScreenSize.expanded;
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Phones turned sideways are wide but short: use side navigation and
  /// side-by-side content instead of tall stacked layouts.
  bool get useSideNavigation => !isCompact || isLandscape;
}

/// Centers content and limits its width on large screens so text lines and
/// cards do not stretch across a whole tablet / desktop window.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.maxWidth = 1200});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Lays children out in a responsive grid of columns: 1 column on phones,
/// 2 on medium screens and up to [maxColumns] on large ones.
class ResponsiveColumns extends StatelessWidget {
  const ResponsiveColumns({
    super.key,
    required this.children,
    this.spacing = 12,
    this.maxColumns = 3,
    this.minItemWidth = 320,
  });

  final List<Widget> children;
  final double spacing;
  final int maxColumns;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = (constraints.maxWidth / minItemWidth).floor();
        columns = columns.clamp(1, maxColumns);
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
        final itemWidth =
            ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                .floorToDouble();
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
