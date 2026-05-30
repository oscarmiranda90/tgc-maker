import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tgc_maker/core/constants.dart';
import 'package:tgc_maker/parallax/tilt_state.dart';

class TiltController {
  final _streamController = StreamController<TiltState>.broadcast();
  Stream<TiltState> get stream => _streamController.stream;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  Ticker? _ticker;

  double _tiltX = 0.0;
  double _tiltY = 0.0;
  double _lightX = 0.0;
  double _lightY = 0.0;

  double _gyroTiltX = 0.0;
  double _gyroTiltY = 0.0;

  double _elapsedSeconds = 0.0;

  void start(TickerProvider vsync) {
    if (!kIsWeb) {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onAccelEvent);
    }

    _ticker = vsync.createTicker(_onTick)..start();
  }

  void stop() {
    _accelSub?.cancel();
    _ticker?.stop();
    _ticker?.dispose();
  }

  void dispose() {
    stop();
    _streamController.close();
  }

  void _onAccelEvent(AccelerometerEvent event) {
    final nx = (event.x / 9.8).clamp(-1.0, 1.0);
    final ny = (event.y / 9.8).clamp(-1.0, 1.0);
    _gyroTiltX = ny * TgcConstants.maxTilt;
    _gyroTiltY = -nx * TgcConstants.maxTilt;
  }

  void setDragLight(double nx, double ny) {
    _lightX = nx;
    _lightY = ny;
    _tiltY = nx * TgcConstants.maxTilt;
    _tiltX = -ny * TgcConstants.maxTilt;
  }

  void resetToGyro() {
    _gyroTiltX = _tiltX;
    _gyroTiltY = _tiltY;
  }

  void _onTick(Duration elapsed) {
    _elapsedSeconds = elapsed.inMilliseconds / 1000.0;

    if (kIsWeb) {
      _gyroTiltX = sin(_elapsedSeconds * 0.65) * 0.15;
      _gyroTiltY = cos(_elapsedSeconds * 0.48) * 0.15;
    }

    const s = TgcConstants.gyroSmoothing;
    _tiltX += (_gyroTiltX - _tiltX) * s;
    _tiltY += (_gyroTiltY - _tiltY) * s;
    _lightX += ((_gyroTiltY / TgcConstants.maxTilt).clamp(-1.0, 1.0) - _lightX) * s;
    _lightY += ((-_gyroTiltX / TgcConstants.maxTilt).clamp(-1.0, 1.0) - _lightY) * s;

    _streamController.add(TiltState(
      tiltX: _tiltX,
      tiltY: _tiltY,
      lightX: _lightX,
      lightY: _lightY,
      time: _elapsedSeconds,
    ));
  }
}
