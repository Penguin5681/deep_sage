import 'package:deep_sage/core/models/user_api_model.dart';
import 'package:flutter/cupertino.dart';

class KaggleUpdateService {
  static final KaggleUpdateService _instance = KaggleUpdateService._internal();

  factory KaggleUpdateService() {
    return _instance;
  }

  KaggleUpdateService._internal();

  final ValueNotifier<UserApi?> kaggleCredentials = ValueNotifier<UserApi?>(null);

  void updateKaggleCreds(String kaggleUsername, String kaggleApiKey) {
    kaggleCredentials.value = UserApi(
      kaggleUserName: kaggleUsername,
      kaggleApiKey: kaggleApiKey,
    );
  }
}