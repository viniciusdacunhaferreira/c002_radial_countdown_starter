// ignore_for_file: public_member_api_docs, sort_constructors_first
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

  void _stop() {
    setState(() {
      _ticker.stop();
      _remainingTime = _timer;
      _elapsedTimeWhenPaused = Duration.zero;
      _remainingTimeInSeconds = _timer.inSeconds;
      _status = CountdownStatus.idle;
    });
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
    const double radius = maxWidth / 2;
    final double beginValue = min(
      (_remainingTimeInSeconds + 1) / _timer.inSeconds,
      1,
    );
    final double endValue = _remainingTimeInSeconds / _timer.inSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(seconds: 1),
              tween: Tween<double>(begin: beginValue, end: endValue),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CounterCircle(
                  radius: radius,
                  value: value,
                  strokeWidth: 12,
                );
              },
            ),
            Text(
              _remainingTimeInSeconds.toString(),
              style: TextStyle(
                fontSize: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Visibility(
              visible: _status.isCounting || _status.isPaused,
              child: Positioned(
                bottom: 45,
                child: IconButton(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        IconButton.filled(icon: _buildPlayPauseIcon(), onPressed: _playPause),
      ],
    );
  }
}

class CounterCircle extends StatelessWidget {
  const CounterCircle({
    super.key,
    required this.radius,
    required this.value,
    this.strokeWidth = 1,
    this.valueColor,
    this.backgroundColor,
  });

  final double radius;
  final double value;
  final double strokeWidth;
  final Color? valueColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    Color resolvedValueColor =
        valueColor ?? Theme.of(context).colorScheme.primary;
    Color resolvedBackgroundColor =
        valueColor ?? Theme.of(context).colorScheme.primaryContainer;
    final dim = 2 * radius;

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(dim, dim),
          painter: CirclePainter(
            radius: radius,
            value: 1,
            strokeWidth: strokeWidth,
            color: resolvedBackgroundColor,
          ),
        ),
        CustomPaint(
          size: Size(dim, dim),
          painter: CirclePainter(
            radius: radius,
            value: value,
            strokeWidth: strokeWidth,
            color: resolvedValueColor,
          ),
        ),
      ],
    );
  }
}

class CirclePainter extends CustomPainter {
  CirclePainter({
    required this.radius,
    required this.value,
    required this.strokeWidth,
    required this.color,
  });

  final double radius;
  final double value;
  final double strokeWidth;
  final Color color;

  double get sweepAngle => value * 2 * pi;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = strokeWidth;
    paint.strokeCap = StrokeCap.round;

    final diameter = size.shortestSide - strokeWidth;
    final Rect rect =
        Offset(strokeWidth / 2, strokeWidth / 2) & Size(diameter, diameter);
    const double startAngle = 3 * pi / 2;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CirclePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
