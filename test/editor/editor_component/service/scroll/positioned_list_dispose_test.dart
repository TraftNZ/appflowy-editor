import 'package:appflowy_editor/src/flutter/scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression test for a use-after-dispose on unmount.
  //
  // Scrolling queues a position update for the end of the frame. If the list
  // is removed from the tree in that same frame — an editor section scrolled
  // out of a lazy list, a document reloaded underneath it — the enclosing
  // ScrollablePositionedList disposes its item-position notifier before the
  // queued callback runs, and publishing the positions then threw
  // "A ValueNotifier<Iterable<ItemPosition>> was used after being disposed".
  testWidgets(
    'a position update queued before unmount is dropped',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 300,
            child: ScrollablePositionedList.builder(
              itemCount: 50,
              itemBuilder: (context, index) => SizedBox(
                height: 40,
                child: Text('Item $index'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Queue the update, then take the list away before the frame ends.
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(100);
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}
