import 'dart:ui';

import 'package:flow_read/widgets/home/home_hover_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('updates surface color on hover', (tester) async {
    const baseColor = Color(0x11000000);
    const hoverColor = Color(0x22000000);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: HomeHoverSurface(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(8)),
              backgroundColor: baseColor,
              hoverBackgroundColor: hoverColor,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    expect(_surfaceColor(tester), baseColor);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(HomeHoverSurface)));
    await tester.pumpAndSettle();

    expect(_surfaceColor(tester), hoverColor);
  });
}

Color? _surfaceColor(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(HomeHoverSurface),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (container.decoration as BoxDecoration?)?.color;
}
