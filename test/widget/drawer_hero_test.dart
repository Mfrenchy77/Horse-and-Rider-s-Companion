import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('drawer hamburger hero morphs to close', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (context) => Hero(
                tag: 'drawer-hamburger-x',
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                const SizedBox(height: 120),
                Align(
                  alignment: Alignment.topRight,
                  child: Hero(
                    tag: 'drawer-hamburger-x',
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(
                        // use a builder context later when tapped
                        tester.element(find.byType(Scaffold)),
                      ).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Open drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Close button should be present
    expect(find.byIcon(Icons.close), findsWidgets);

    // Tap close
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    // Drawer should be closed
    expect(find.byType(Drawer), findsNothing);
  });
}
