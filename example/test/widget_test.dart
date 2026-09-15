import 'package:flutter/rendering.dart';
import 'package:fog_reveal/fog_reveal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fog_reveal_example/main.dart';

Widget host(Widget child) => MaterialApp(home: Center(child: child));

void main() {
  testWidgets('real packaged shader loads, draws, reloads and disposes',
      (tester) async {
    final errors = <Object>[];
    final key = GlobalKey();
    Widget subject(int seed) => host(RepaintBoundary(
        key: key,
        child: FogReveal(
            progress: 0.5,
            style: FogStyle(seed: seed, textureSize: 32),
            onError: (e, s) => errors.add(e),
            child: const SizedBox(
                width: 80, height: 60, child: ColoredBox(color: Colors.red)))));
    await tester.pumpWidget(subject(7));
    // Let native shader/image futures complete outside the fake test clock.
    for (var i = 0;
        i < 50 &&
            find
                .descendant(
                    of: find.byType(FogReveal),
                    matching: find.byType(CustomPaint))
                .evaluate()
                .isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(errors, isEmpty);
    expect(
        find.descendant(
            of: find.byType(FogReveal), matching: find.byType(CustomPaint)),
        findsOneWidget);
    await tester.pump(const Duration(milliseconds: 16));
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await tester.runAsync(() => boundary.toImage());
    final bytes = await tester.runAsync(() => image!.toByteData());
    expect(bytes, isNotNull);
    // Organic output must have spatial variation over a uniform red child.
    final colors = <int>{};
    for (var i = 0; i < bytes!.lengthInBytes; i += 4) {
      colors.add(bytes.getUint32(i));
    }
    expect(colors.length, greaterThan(10));
    image!.dispose();
    await tester.pumpWidget(subject(8));
    await tester.pumpWidget(subject(9));
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(errors, isEmpty);
  });

  testWidgets('shader preserves the demo organic fog and drifting texture',
      (tester) async {
    final key = GlobalKey();
    var ready = 0;
    final errors = <Object>[];
    Widget subject(double progress) => host(RepaintBoundary(
          key: key,
          child: FogReveal(
            progress: progress,
            style: const FogStyle(
                color: Color(0xFF0000FF), seed: 7, textureSize: 32),
            onReady: () => ready++,
            onError: (e, s) => errors.add(e),
            child: const SizedBox(
                width: 80,
                height: 60,
                child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFFF0000)))),
          ),
        ));
    await tester.pumpWidget(subject(0));
    for (var i = 0; i < 50 && ready == 0; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(ready, 1);
    expect(errors, isEmpty);
    for (final progress in [
      0.0,
      double.nan,
      double.negativeInfinity,
      -2.0,
      0.25,
      0.5,
      0.75,
      1.0,
      2.0,
      double.infinity
    ]) {
      await tester.pumpWidget(subject(progress));
      expect(find.byType(ColoredBox), findsNothing);
      expect(find.byType(Opacity), findsNothing);
      expect(
          find.descendant(
              of: find.byType(FogReveal), matching: find.byType(CustomPaint)),
          findsOneWidget);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await tester.runAsync(() => boundary.toImage());
      final bytes = (await tester.runAsync(() => image!.toByteData()))!;
      final colors = <int>{};
      for (var i = 0; i < bytes.lengthInBytes; i += 4) {
        colors.add(bytes.getUint32(i));
        if (progress.isNaN || progress <= 0) {
          expect(bytes.getUint8(i), 0);
          expect(bytes.getUint8(i + 2), 255);
        } else if (progress >= 1) {
          expect(bytes.getUint8(i), 255);
          expect(bytes.getUint8(i + 2), 0);
        }
      }
      if (progress == 0.5) expect(colors.length, greaterThan(10));
      if (progress == 0.25) {
        final width = image!.width;
        final height = image.height;
        final sidePixels = [
          width ~/ 2,
          (height - 1) * width + width ~/ 2,
          (height ~/ 2) * width,
          (height ~/ 2) * width + width - 1
        ];
        // Organic dissolve must not create a uniformly cleared border.
        expect(sidePixels.any((pixel) => bytes.getUint8(pixel * 4 + 2) > 200),
            isTrue);
      }
      image!.dispose();
    }
    expect(ready, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('example opens and exposes the essential controls',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FogRevealExample());
    expect(tester.takeException(), isNull);
    expect(find.text('Fog reveal'), findsOneWidget);
    expect(find.text('Replay'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
  });

  testWidgets('controller-free widget follows revealed changes',
      (tester) async {
    var ready = false;
    Widget subject(bool revealed) => host(
          AnimatedFogReveal(
            revealed: revealed,
            duration: const Duration(seconds: 1),
            curve: Curves.linear,
            onReady: () => ready = true,
            child: const SizedBox(width: 80, height: 60),
          ),
        );

    await tester.pumpWidget(subject(false));
    for (var i = 0; i < 50 && !ready; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(ready, isTrue);
    expect(tester.widget<FogReveal>(find.byType(FogReveal)).progress, 0);

    await tester.pumpWidget(subject(true));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.widget<FogReveal>(find.byType(FogReveal)).progress,
      closeTo(0.4, 0.02),
    );

    await tester.pumpWidget(subject(false));
    await tester.pumpAndSettle();
    expect(tester.widget<FogReveal>(find.byType(FogReveal)).progress, 0);
  });

  testWidgets('loop starts from an idle external controller and repeats',
      (tester) async {
    final controller = FogRevealController(
      vsync: tester,
      duration: const Duration(milliseconds: 400),
    );
    addTearDown(controller.dispose);
    var ready = false;

    Widget subject(bool loop) => host(
          AnimatedFogReveal(
            controller: controller,
            loop: loop,
            curve: Curves.linear,
            onReady: () => ready = true,
            child: const SizedBox(width: 80, height: 60),
          ),
        );

    await tester.pumpWidget(subject(false));
    for (var i = 0; i < 50 && !ready; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(ready, isTrue);
    expect(controller.isAnimating, isFalse);

    await tester.pumpWidget(subject(true));
    expect(controller.isAnimating, isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.isAnimating, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.value, closeTo(0.25, 0.03));

    await tester.pumpWidget(subject(false));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'internal playback honors initial progress and does not replay on reload',
      (tester) async {
    var readyCount = 0;
    Widget subject(int seed) => host(
          AnimatedFogReveal(
            initialProgress: 0.4,
            duration: const Duration(seconds: 1),
            curve: Curves.linear,
            style: FogStyle(seed: seed, textureSize: 32),
            onReady: () => readyCount++,
            child: const SizedBox(width: 80, height: 60),
          ),
        );

    await tester.pumpWidget(subject(20));
    for (var i = 0; i < 50 && readyCount == 0; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(readyCount, 1);
    expect(tester.widget<FogReveal>(find.byType(FogReveal)).progress, 0.4);
    await tester.pumpAndSettle();
    expect(tester.widget<FogReveal>(find.byType(FogReveal)).progress, 1);

    await tester.pumpWidget(subject(21));
    for (var i = 0; i < 50 && readyCount < 2; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(readyCount, 2);
    expect(tester.widget<FogReveal>(find.byType(FogReveal)).progress, 1);
  });

  testWidgets(
      'managed loop moves to a replacement controller and stops on dispose',
      (tester) async {
    final first = FogRevealController(
      vsync: tester,
      duration: const Duration(milliseconds: 400),
    );
    final second = FogRevealController(
      vsync: tester,
      duration: const Duration(milliseconds: 400),
    );
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    var ready = false;

    Widget subject(FogRevealController controller) => host(
          AnimatedFogReveal(
            controller: controller,
            loop: true,
            onReady: () => ready = true,
            child: const SizedBox(width: 80, height: 60),
          ),
        );

    await tester.pumpWidget(subject(first));
    for (var i = 0; i < 50 && !ready; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(first.isAnimating, isTrue);

    await tester.pumpWidget(subject(second));
    expect(first.isAnimating, isFalse);
    expect(second.isAnimating, isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(second.isAnimating, isFalse);
  });
}
