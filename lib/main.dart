import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16.0),
          // Use Center as layout has unconstrained width (loose constraints),
          // together with SizedBox to specify the max width (tight constraints)
          // See this thread for more info:
          // https://twitter.com/biz84/status/1445400059894542337
          child: Center(
            child: SizedBox(
              width: 300, // max allowed width
              child: CountdownAndRestart(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Main demo UI (countdown + restart button)
class CountdownAndRestart extends StatefulWidget {
  const CountdownAndRestart({super.key});

  @override
  CountdownAndRestartState createState() => CountdownAndRestartState();
}

enum CountdownStatus {
  idle,
  counting,
  paused,
  terminated;

  bool get isIdle => this == idle;
  bool get isCounting => this == counting;
  bool get isPaused => this == paused;
  bool get isTerminated => this == terminated;
}

class CountdownAndRestartState extends State<CountdownAndRestart>
    with TickerProviderStateMixin {
  static const maxWidth = 300.0;

  final Duration _timer = const Duration(seconds: 10);
  CountdownStatus _status = CountdownStatus.idle;

  late Duration _remainingTime;
  late Duration _elapsedTimeWhenPaused;
  late int _remainingTimeInSeconds;

  late final Ticker _ticker;

  void _start() {
    setState(() {
      _ticker.start();
      _status = CountdownStatus.counting;
    });
  }

  void _pause() {
    if (!_status.isCounting) return;
    setState(() {
      _ticker.stop();
      _elapsedTimeWhenPaused = _timer - _remainingTime;
      _status = CountdownStatus.paused;
    });
  }

  void _resume() {
    setState(() {
      if (_status.isCounting) return;
      _ticker.start();
      _status = CountdownStatus.counting;
    });
  }

  void _terminate() {
    setState(() {
      _ticker.stop();
      _remainingTime = _timer;
      _elapsedTimeWhenPaused = Duration.zero;
      _status = CountdownStatus.terminated;
    });
  }

  void _playPause() {
    if (_status.isIdle) {
      _start();
    } else if (_status.isCounting) {
      _pause();
    } else if (_status.isPaused) {
      _resume();
    } else if (_status.isTerminated) {
      _start();
    }
  }

  Widget _buildPlayPauseIcon() {
    if (_status.isCounting) {
      return const Icon(Icons.pause);
    }
    if (_status.isPaused) {
      return const Icon(Icons.play_arrow);
    }
    if (_status.isTerminated) {
      return const Icon(Icons.replay);
    }
    return const Icon(Icons.play_arrow);
  }

  @override
  void initState() {
    super.initState();

    _remainingTime = _timer;
    _elapsedTimeWhenPaused = Duration.zero;
    _remainingTimeInSeconds = _remainingTime.inSeconds;

    _ticker = createTicker((elapsed) {
      _remainingTime = _timer - elapsed - _elapsedTimeWhenPaused;

      if (_remainingTime.isNegative) {
        _terminate();
        return;
      }
      if (_remainingTimeInSeconds != _remainingTime.inSeconds) {
        setState(() {
          _remainingTimeInSeconds = _remainingTime.inSeconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double beginValue = min(
      (_remainingTimeInSeconds + 1) / _timer.inSeconds,
      1,
    );
    final double endValue = _remainingTimeInSeconds / _timer.inSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FittedBox(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(_remainingTimeInSeconds.toString()),
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 1),
                tween: Tween<double>(begin: beginValue, end: endValue),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                    strokeAlign: -1,
                    value: value,
                    strokeWidth: 2,
                    strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        IconButton.filled(icon: _buildPlayPauseIcon(), onPressed: _playPause),
      ],
    );
  }
}
