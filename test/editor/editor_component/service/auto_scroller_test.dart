import 'package:appflowy_editor/src/editor/editor_component/service/scroll/auto_scroller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures the rect passed to [startAutoScrollIfNecessary] without triggering
/// real scrolling, so we can assert on the proxy rect computation.
class _CapturingAutoScroller extends AutoScroller {
  _CapturingAutoScroller(super.scrollable);

  Rect? capturedRect;

  @override
  void startAutoScrollIfNecessary(Rect dragTarget, {Duration? duration}) {
    capturedRect = dragTarget;
    // intentionally do not call super — we only want the rect
  }
}

void main() {
  group('AutoScroller.startAutoScroll', () {
    late ScrollableState scrollableState;

    setUp(() async {});

    /// Builds a minimal scrollable so we can obtain a real [ScrollableState].
    Future<void> buildScrollable(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SingleChildScrollView(
            child: SizedBox(height: 2000),
          ),
        ),
      );
      await tester.pumpAndSettle();
      scrollableState =
          tester.state<ScrollableState>(find.byType(Scrollable).first);
    }

    // Regression test for:
    // When dragging the left selection handle upward on iOS/Android, the screen
    // was scrolling DOWN (showing content below) instead of UP (showing content
    // above). The root cause was that the proxy rect used for auto-scroll
    // detection extended 220px DOWNWARD from the selection start, so when the
    // handle was in the lower portion of the viewport the rect's bottom exceeded
    // the viewport edge and triggered a downward scroll.
    testWidgets(
      'left handle drag (AxisDirection.up) — proxy rect extends upward from offset',
      (tester) async {
        await buildScrollable(tester);

        final scroller = _CapturingAutoScroller(scrollableState);
        const offset = Offset(100, 500);
        const edgeOffset = 200.0;

        scroller.startAutoScroll(
          offset,
          direction: AxisDirection.up,
        );

        expect(scroller.capturedRect, isNotNull);

        // Rect must extend UPWARD: top = offset.dy - edgeOffset, bottom = offset.dy
        expect(
          scroller.capturedRect!.top,
          offset.dy - edgeOffset,
          reason: 'proxy rect should start edgeOffset pixels ABOVE the handle',
        );
        expect(
          scroller.capturedRect!.bottom,
          offset.dy,
          reason:
              'proxy rect bottom should be at the handle position, not below it',
        );

        // Guard: bottom must NOT be offset.dy + edgeOffset (the old buggy value
        // that caused downward scrolling when the handle was near the bottom of
        // the viewport).
        expect(
          scroller.capturedRect!.bottom,
          isNot(offset.dy + edgeOffset),
          reason:
              'old buggy value extended the rect downward, triggering wrong-direction scroll',
        );
      },
    );

    testWidgets(
      'right handle drag (AxisDirection.down) — proxy rect is centered on offset',
      (tester) async {
        await buildScrollable(tester);

        final scroller = _CapturingAutoScroller(scrollableState);
        const offset = Offset(100, 300);
        const edgeOffset = 200.0;

        scroller.startAutoScroll(
          offset,
          direction: AxisDirection.down,
        );

        expect(scroller.capturedRect, isNotNull);

        // For AxisDirection.down the rect starts at offset and extends downward.
        expect(
          scroller.capturedRect!.top,
          offset.dy,
          reason: 'proxy rect should start at the handle position',
        );
        expect(
          scroller.capturedRect!.bottom,
          offset.dy + edgeOffset,
          reason: 'proxy rect should extend edgeOffset pixels BELOW the handle',
        );
        expect(scroller.capturedRect!.height, edgeOffset);
      },
    );

    testWidgets(
      'no direction — proxy rect is centered on offset',
      (tester) async {
        await buildScrollable(tester);

        final scroller = _CapturingAutoScroller(scrollableState);
        const offset = Offset(50, 200);
        const edgeOffset = 100.0;

        scroller.startAutoScroll(offset, edgeOffset: edgeOffset);

        expect(scroller.capturedRect, isNotNull);
        expect(scroller.capturedRect!.center, offset);
        expect(scroller.capturedRect!.width, edgeOffset);
        expect(scroller.capturedRect!.height, edgeOffset);
      },
    );
  });

  group('AutoScroller convergence', () {
    /// Builds a scrollable of exactly [viewportHeight] with 600px of content
    /// and returns its state, so the drag target can be made deliberately
    /// taller or shorter than the viewport.
    Future<ScrollableState> buildSizedScrollable(
      WidgetTester tester,
      double viewportHeight,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: viewportHeight,
              width: 300,
              child: const SingleChildScrollView(
                child: SizedBox(height: 600),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return tester.state<ScrollableState>(find.byType(Scrollable).first);
    }

    // Regression test for an unbounded auto-scroll bounce.
    //
    // A drag target taller than the viewport overruns BOTH edges at once, so
    // every pass scrolls towards one edge and the next pass scrolls straight
    // back. Selection-driven auto scroll passes duration zero, so that bounce
    // never yields to a frame: `_scroll` recursed through the microtask queue
    // forever, pinning a core and growing the heap without bound. Upstream
    // Flutter only catches this with a debug assert ("Drag target size is
    // larger than scrollable size, which may cause bouncing"), which this fork
    // had replaced with an empty if-block.
    //
    // A regression here manifests as a hang, not a failed expectation — there
    // is no way to bound a starved microtask queue from inside a widget test.
    testWidgets(
      'a drag target taller than the viewport does not scroll at all',
      (tester) async {
        final scrollable = await buildSizedScrollable(tester, 120);
        final scroller = AutoScroller(scrollable);
        final viewport = tester.getRect(find.byType(SingleChildScrollView));

        // 220 is the editor's default autoScrollEdgeOffset, well past the
        // 120px viewport built above.
        scroller.startAutoScroll(
          viewport.center,
          edgeOffset: 220,
          duration: Duration.zero,
        );

        expect(
          scroller.scrolling,
          isFalse,
          reason: 'the scroller must bail out instead of bouncing forever',
        );
        expect(scrollable.position.pixels, 0);

        await tester.pump();
        expect(scroller.scrolling, isFalse);
        expect(scrollable.position.pixels, 0);
      },
    );

    // The bounce guard clamps each pass to the distance still available before
    // the opposite edge of the drag target leaves the viewport. This asserts
    // the clamp does not disable auto scrolling outright in the ordinary case
    // it exists to serve.
    testWidgets(
      'a drag target overrunning one edge still scrolls and then settles',
      (tester) async {
        final scrollable = await buildSizedScrollable(tester, 500);
        final scroller = AutoScroller(scrollable);
        final viewport = tester.getRect(find.byType(SingleChildScrollView));

        // Centred near the bottom edge: the target's bottom overruns the
        // viewport while its top stays inside, so there is real headroom.
        scroller.startAutoScroll(
          Offset(viewport.center.dx, viewport.bottom - 40),
          duration: Duration.zero,
        );
        await tester.pumpAndSettle();

        expect(
          scrollable.position.pixels,
          greaterThan(0),
          reason: 'auto scroll must still reveal the overrunning edge',
        );
        expect(
          scroller.scrolling,
          isFalse,
          reason: 'the scroll must terminate once the edge is revealed',
        );
      },
    );
  });
}
