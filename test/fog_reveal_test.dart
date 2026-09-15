import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fog_reveal/fog_reveal.dart';
import 'package:fog_reveal/src/noise.dart';

Widget host(Widget child) => MaterialApp(home: Center(child: child));
Widget fog(double progress, {bool block = false, VoidCallback? onTap}) =>
    FogReveal(
      progress: progress,
      blockInteraction: block,
      child: GestureDetector(
        onTap: onTap,
        child: const SizedBox(width: 80, height: 60, child: Text('content')),
      ),
    );

void main() {
  testWidgets('loading never adds a solid or fading cover', (tester) async {
    for (final progress in [
      double.nan,
      double.negativeInfinity,
      -4.0,
      0.0,
      0.5,
      1.0,
      4.0,
      double.infinity
    ]) {
      await tester.pumpWidget(host(fog(progress)));
      expect(find.byType(ColoredBox), findsNothing);
      expect(find.byType(Opacity), findsNothing);
      expect(find.text('content'), findsOneWidget);
    }
  });

  testWidgets('interaction stays opt-in and unlocks after reveal',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(fog(0, onTap: () => taps++)));
    await tester.tap(find.text('content'));
    expect(taps, 1);
    await tester.pumpWidget(host(fog(0.5, block: true, onTap: () => taps++)));
    await tester.tap(find.text('content'), warnIfMissed: false);
    expect(taps, 1);
    await tester.pumpWidget(host(fog(1, block: true, onTap: () => taps++)));
    await tester.tap(find.text('content'));
    expect(taps, 2);
  });

  testWidgets('animated reveal reverses continuously and reports endpoints',
      (tester) async {
    final controller = FogRevealController(
        vsync: tester, duration: const Duration(seconds: 1));
    var ends = 0;
    await tester.pumpWidget(host(AnimatedFogReveal(
      controller: controller,
      curve: Curves.linear,
      onEnd: () => ends++,
      child: const SizedBox(width: 80, height: 60),
    )));
    expect(ends, 0);
    expect(controller.value, 0);
    controller.reveal();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final before = tester.widget<FogReveal>(find.byType(FogReveal)).progress;
    expect(before, closeTo(0.4, 0.01));
    controller.cover();
    await tester.pump();
    expect(tester.widget<FogReveal>(find.byType(FogReveal)).progress, before);
    await tester.pumpAndSettle();
    expect(controller.value, 0);
    expect(ends, 1);
    controller.replay();
    await tester.pumpAndSettle();
    expect(controller.value, 1);
    expect(ends, 2);
    await tester.pumpWidget(const SizedBox());
    controller.seek(0);
    expect(ends, 2);
    controller.dispose();
  });

  testWidgets('animated reveal rebinds controller and uses latest callback',
      (tester) async {
    final a = FogRevealController(vsync: tester);
    final b = FogRevealController(vsync: tester, value: 0.6);
    var oldEnds = 0;
    var newEnds = 0;
    Widget subject(FogRevealController controller, VoidCallback callback) =>
        host(AnimatedFogReveal(
          controller: controller,
          curve: Curves.linear,
          onEnd: callback,
          child: const SizedBox(width: 80, height: 60),
        ));
    await tester.pumpWidget(subject(a, () => oldEnds++));
    await tester.pumpWidget(subject(b, () => newEnds++));
    a.seek(1);
    await tester.pump();
    expect(oldEnds, 0);
    expect(newEnds, 0);
    expect(tester.widget<FogReveal>(find.byType(FogReveal)).progress, 0.6);
    b.seek(1);
    await tester.pump();
    expect(newEnds, 1);
    await tester.pumpWidget(subject(b, () => oldEnds++));
    b.seek(0);
    expect(oldEnds, 1);
    await tester.pumpWidget(const SizedBox());
    b.seek(1);
    expect(newEnds, 1);
    expect(oldEnds, 1);
    a.dispose();
    b.dispose();
  });

  testWidgets('semantics can stay hidden until reveal', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final p in [0.0, 1.0]) {
      await tester.pumpWidget(
        host(
          FogReveal(
            progress: p,
            excludeSemantics: true,
            child: SizedBox(
              width: 80,
              height: 60,
              child: Semantics(label: 'secret card', child: SizedBox()),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('secret card'),
          p == 0 ? findsNothing : findsOneWidget);
    }
    semantics.dispose();
  });

  testWidgets('zero size and unbounded parent with sized child are safe',
      (tester) async {
    await tester.pumpWidget(
      host(
        const SingleChildScrollView(
          child: Column(
            children: [
              FogReveal(progress: 0.5, child: SizedBox.shrink()),
              FogReveal(progress: 0.5, child: SizedBox(width: 80, height: 60)),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  // Package-root tests have no packages/fog_reveal asset namespace. The
  // example consumer verifies successful loading; here we verify failure behavior.
  testWidgets('missing shader reports failure once and can retry',
      (tester) async {
    final errors = <Object>[];
    Widget subject(int identity) => host(
          FogReveal(
            progress: 0.5,
            key: ValueKey(identity),
            onError: (e, s) => errors.add(e),
            child: const SizedBox(width: 80, height: 60),
          ),
        );
    await tester.pumpWidget(subject(1));
    for (var i = 0; i < 50 && errors.isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pump();
    expect(errors, hasLength(1));
    expect(find.byType(ColoredBox), findsNothing);
    await tester.pumpWidget(subject(1));
    expect(errors, hasLength(1));
    await tester.pumpWidget(subject(2));
    for (var i = 0; i < 50 && errors.length < 2; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(errors, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('seeded noise is repeatable and changes with seed',
      (tester) async {
    Future<List<int>> pixels(int seed) async {
      final image = await createNoiseTexture(size: 16, seed: seed);
      try {
        return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
            .buffer
            .asUint8List()
            .toList();
      } finally {
        image.dispose();
      }
    }

    final a = await tester.runAsync(() => pixels(10));
    final b = await tester.runAsync(() => pixels(10));
    final c = await tester.runAsync(() => pixels(11));
    expect(a, b);
    expect(a, isNot(c));
  });

  testWidgets('matching active widgets share one noise texture',
      (tester) async {
    final first = await tester.runAsync(
      () => acquireNoiseTexture(size: 16, seed: 10),
    );
    final second = await tester.runAsync(
      () => acquireNoiseTexture(size: 16, seed: 10),
    );
    expect(identical(first!.image, second!.image), isTrue);
    first.release();
    second.release();
  });

  testWidgets('controller supports seek, pause, resume, cover and replay',
      (tester) async {
    final controller = FogRevealController(
        vsync: tester, duration: const Duration(seconds: 1));
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(AnimatedFogReveal(
      controller: controller,
      curve: Curves.linear,
      style: FogStyle.dark.copyWith(softness: 0.2),
      child: const SizedBox(width: 80, height: 60),
    )));
    controller.reveal();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.value, closeTo(0.4, 0.01));
    controller.pause();
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.value, closeTo(0.4, 0.01));
    controller.resume();
    await tester.pumpAndSettle();
    expect(controller.isCompleted, isTrue);
    controller.cover();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    controller.pause();
    controller.resume();
    await tester.pumpAndSettle();
    expect(controller.value, 0);
    controller.seek(0.6);
    await tester.pump();
    expect(tester.widget<FogReveal>(find.byType(FogReveal)).progress, 0.6);
    controller.seek(2);
    expect(controller.value, 1);
    expect(() => controller.seek(double.nan), throwsArgumentError);
    controller.replay();
    expect(controller.value, 0);
    await tester.pumpAndSettle();
    controller.toggle();
    await tester.pumpAndSettle();
    expect(controller.value, 0);
    controller.repeat(reverse: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    expect(controller.status, AnimationStatus.reverse);
    controller.pause();
    controller.resume();
    await tester.pumpAndSettle();
    expect(controller.value, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('transition follows replacement animation without stale updates',
      (tester) async {
    final a = FogRevealController(vsync: tester, value: 0.2);
    final b = FogRevealController(vsync: tester, value: 0.8);
    Widget subject(Animation<double> animation) => host(FogTransition(
          animation: animation,
          curve: Curves.linear,
          child: const SizedBox(width: 80, height: 60),
        ));
    await tester.pumpWidget(subject(a));
    await tester.pumpWidget(subject(b));
    a.seek(0);
    await tester.pump();
    expect(tester.widget<FogReveal>(find.byType(FogReveal)).progress, 0.8);
    await tester.pumpWidget(const SizedBox());
    a.dispose();
    b.dispose();
  });

  testWidgets('transition keeps raw motion separate from eased reveal',
      (tester) async {
    final controller = FogRevealController(vsync: tester, value: 0.25);
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(FogTransition(
      animation: controller,
      child: const SizedBox(width: 80, height: 60),
    )));
    final reveal = tester.widget<FogReveal>(find.byType(FogReveal));
    expect(reveal.motionProgress, 0.25);
    expect(reveal.progress, Curves.easeInOutCubic.transform(0.25));
  });

  test('style copy preserves values and rejects invalid ranges', () {
    const style = FogStyle(seed: 9, drift: 2);
    expect(style.copyWith(softness: 0.2).seed, 9);
    expect(style.copyWith(softness: 0.2).drift, 2);
    expect(() => FogStyle(softness: 0), throwsAssertionError);
    expect(() => FogStyle(textureSize: 2048), throwsAssertionError);
  });
}
