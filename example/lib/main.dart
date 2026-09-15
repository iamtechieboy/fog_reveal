import 'package:flutter/material.dart';
import 'package:fog_reveal/fog_reveal.dart';

void main() => runApp(const FogRevealExample());

/// A small, complete fog_reveal example.
class FogRevealExample extends StatelessWidget {
  /// Creates the example app.
  const FogRevealExample({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087F5B)),
          useMaterial3: true,
        ),
        home: const FogRevealPage(),
      );
}

/// Demonstrates replay, looping, and manual progress.
class FogRevealPage extends StatefulWidget {
  /// Creates the example page.
  const FogRevealPage({super.key});

  @override
  State<FogRevealPage> createState() => _FogRevealPageState();
}

class _FogRevealPageState extends State<FogRevealPage>
    with SingleTickerProviderStateMixin {
  late final FogRevealController _fog;
  bool _loop = false;

  @override
  void initState() {
    super.initState();
    _fog = FogRevealController(vsync: this);
  }

  @override
  void dispose() {
    _fog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Fog reveal')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'The card appears through a soft, organic fog mask.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              AnimatedFogReveal(
                controller: _fog,
                loop: _loop,
                onReady: _fog.replay,
                borderRadius: BorderRadius.circular(28),
                child: const _DemoCard(),
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _fog,
                builder: (context, child) => Column(
                  children: [
                    Text('${(_fog.value * 100).round()}% revealed'),
                    Slider(
                      value: _fog.value,
                      onChanged: (value) {
                        _fog.seek(value);
                        if (_loop) setState(() => _loop = false);
                      },
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _fog.replay,
                      icon: const Icon(Icons.replay),
                      label: const Text('Replay'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _loop = !_loop),
                      icon: Icon(_loop ? Icons.pause : Icons.repeat),
                      label: Text(_loop ? 'Stop loop' : 'Loop'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _DemoCard extends StatelessWidget {
  const _DemoCard();

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1.32,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 122, 127, 161),
                Color.fromARGB(255, 38, 36, 70)
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 44,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  'Something beautiful is here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
