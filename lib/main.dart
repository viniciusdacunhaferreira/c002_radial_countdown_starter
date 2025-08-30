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

/// Main demo UI (countdown + restart button)
class CountdownAndRestart extends StatefulWidget {
  const CountdownAndRestart({super.key});

  @override
  CountdownAndRestartState createState() => CountdownAndRestartState();
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
    final double progress = _remainingTime.inSeconds / _timer.inSeconds;
    final bool isRunning = _status.isCounting || _status.isPaused;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Counter(remainingTime: _remainingTime, progressRatio: progress),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: IconButton.filled(
                icon: _buildPlayPauseIcon(),
                onPressed: _playPause,
              ),
            ),
            Visibility(visible: isRunning, child: const SizedBox(width: 8)),
            Expanded(
              flex: isRunning ? 1 : 0,
              child: Visibility(
                visible: isRunning,
                child: IconButton.filled(
                  icon: const Icon(Icons.stop),
                  onPressed: _stop,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class Counter extends StatefulWidget {
  const Counter({
    super.key,
    required this.remainingTime,
    required this.progressRatio,
  });

  final Duration remainingTime;
  final double progressRatio;

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  late double oldProgressRatio;

  @override
  void initState() {
    oldProgressRatio = widget.progressRatio;

    super.initState();
  }

  @override
  void didUpdateWidget(covariant Counter oldWidget) {
    if (oldWidget.progressRatio != widget.progressRatio) {
      oldProgressRatio = oldWidget.progressRatio;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final remainingTimeInSeconds = widget.remainingTime.inSeconds;

        return Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(seconds: 1),
              tween: Tween<double>(
                begin: oldProgressRatio,
                end: widget.progressRatio,
              ),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) {
                return CounterCircle(value: value, strokeWidth: width / 25);
              },
            ),
            Text(
              remainingTimeInSeconds.toString(),
              style: TextStyle(
                fontSize: width / 3,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class CounterCircle extends StatelessWidget {
  const CounterCircle({
    super.key,
    required this.value,
    this.strokeWidth = 1,
    this.valueColor,
    this.backgroundColor,
  });

  final double value;
  final double strokeWidth;
  final Color? valueColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    Color resolvedValueColor = valueColor ?? scheme.primary;
    Color resolvedBackgroundColor = backgroundColor ?? scheme.primaryContainer;

    return AspectRatio(
      aspectRatio: 1.0,
      child: CustomPaint(
        painter: CirclePainter(
          value: value,
          strokeWidth: strokeWidth,
          color: resolvedValueColor,
          backgroundColor: resolvedBackgroundColor,
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  CirclePainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  final double value;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final nominalDiameter = size.shortestSide - strokeWidth;
    final nominalRadius = nominalDiameter / 2;

    Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      nominalRadius,
      backgroundPaint,
    );

    Paint progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rectOffset = Offset(strokeWidth / 2, strokeWidth / 2);
    final rectSize = Size(nominalDiameter, nominalDiameter);
    final Rect rect = rectOffset & rectSize;
    const double startAngle = 3 * pi / 2;
    final double sweepAngle = value * 2 * pi;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CirclePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
