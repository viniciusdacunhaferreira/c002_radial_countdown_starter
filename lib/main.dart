// ignore_for_file: avoid_print

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
  Duration _elapsed = Duration.zero;

  late DateTime _startTime;
  late Duration _remainingTime;
  late int _remainingTimeInSeconds;

  late final Ticker _ticker;

  void _start() {
    setState(() {
      print('Starting');
      print('_elapsed = $_elapsed');
      _startTime = DateTime.now();
      _ticker.start();
      _status = CountdownStatus.counting;
    });
  }

  void _pause() {
    if (!_status.isCounting) return;
    setState(() {
      print('Pausing');
      _ticker.stop();
      _status = CountdownStatus.paused;
    });
  }

  void _resume() {
    setState(() {
      print('Resuming');
      if (_status.isCounting) return;
      _startTime = DateTime.now().subtract(_elapsed);
      _ticker.start();
      _status = CountdownStatus.counting;
    });
  }

  void _terminate() {
    setState(() {
      print('Terminating');
      _ticker.stop();
      _elapsed = Duration.zero;
      _remainingTime = _timer;
      _status = CountdownStatus.terminated;
      print('_elapsed = $_elapsed');
    });
  }

  void _playPause() {
    print(_status);
    if (_status.isIdle) {
      _start();
    } else if (_status.isCounting) {
      _pause();
    } else if (_status.isPaused) {
      _resume();
    } else if (_status.isTerminated) {
      print('Restarting');
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
    _remainingTimeInSeconds = _timer.inSeconds;

    _ticker = createTicker((elapsed) {
      // print('Ticking');
      if (_remainingTime.isNegative) {
        _terminate();
        return;
      }

      _elapsed = DateTime.now().difference(_startTime);
      _remainingTime = _timer - _elapsed;
      if (_remainingTimeInSeconds != _remainingTime.inSeconds) {
        print('$_remainingTimeInSeconds != ${_remainingTime.inSeconds}');
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
    print('Building');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FittedBox(
          child: Stack(
            alignment: AlignmentGeometry.center,
            children: [
              Text(_remainingTimeInSeconds.toString()),
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 1),
                tween: Tween<double>(
                    begin: 1, end: _remainingTimeInSeconds / _timer.inSeconds),
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
