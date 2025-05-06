import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();

  factory HealthService() {
    return _instance;
  }

  HealthService._internal();

  final ValueNotifier<BackendStatus> status = ValueNotifier(BackendStatus.unknown);
  Timer? _timer;

  void startMonitoring() {
    _timer?.cancel();

    checkHealth();

    _timer = Timer.periodic(Duration(seconds: 30), (_) {
      checkHealth();
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('${dotenv.env['DEV_BASE_URL']}/health'));

      if (response.statusCode == 200) {
        status.value = BackendStatus.online;
      } else {
        status.value = BackendStatus.error;
      }
    } catch (e) {
      status.value = BackendStatus.offline;
    }
  }
}

enum BackendStatus {
  online,
  offline,
  error,
  unknown
}