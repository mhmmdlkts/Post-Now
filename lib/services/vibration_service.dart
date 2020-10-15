import 'package:vibration/vibration.dart';

class VibrationService {

  static vibrateGoOffline() async {
    if (await Vibration.hasCustomVibrationsSupport()) {
      Vibration.vibrate(duration: 1000, amplitude: 128);
    } else {
    Vibration.vibrate();
    await Future.delayed(Duration(milliseconds: 500));
    Vibration.vibrate();
    }
  }

  static vibrateGoOnline() async {
    if (await Vibration.hasCustomVibrationsSupport()) {
      Vibration.vibrate(pattern: [0, 250, 50, 150]);
    } else {
      Vibration.vibrate();
      await Future.delayed(Duration(milliseconds: 50));
      Vibration.vibrate();
    }
  }

  static vibrateMessage() async {
    if (await Vibration.hasCustomVibrationsSupport()) {
      Vibration.vibrate(duration: 300);
    } else {
      Vibration.vibrate();
    }
  }

  static vibrateNewOrder() async {
    if (await Vibration.hasCustomVibrationsSupport()) {
      Vibration.vibrate(pattern: [300, 500]);
    } else {
      Vibration.vibrate();
      await Future.delayed(Duration(milliseconds: 300));
      Vibration.vibrate();
    }
  }
}