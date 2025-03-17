/// Provides functionality to update and manage Kaggle API credentials.
///
/// This service uses the Singleton pattern to ensure only one instance exists
/// throughout the application lifecycle. It stores and updates Kaggle username
/// and API key information using a ValueNotifier to enable reactive updates
/// throughout the app.
library;

import 'package:deep_sage/core/models/hive_models/user_api_model.dart';
import 'package:flutter/cupertino.dart';

/// A service responsible for managing Kaggle API credentials.
class KaggleUpdateService {
  /// Singleton instance of the KaggleUpdateService.
  static final KaggleUpdateService _instance = KaggleUpdateService._internal();

  /// Factory constructor that returns the singleton instance.
  ///
  /// This ensures that only one instance of KaggleUpdateService is used
  /// throughout the application.
  factory KaggleUpdateService() {
    return _instance;
  }

  /// Private constructor for the singleton pattern.
  KaggleUpdateService._internal();

  /// Stores the current Kaggle API credentials.
  ///
  /// The ValueNotifier allows widgets to listen to changes in the credentials
  /// and update accordingly.
  final ValueNotifier<UserApi?> kaggleCredentials = ValueNotifier<UserApi?>(
    null,
  );

  /// Updates the Kaggle credentials with the provided username and API key.
  ///
  /// @param kaggleUsername The user's Kaggle username.
  /// @param kaggleApiKey The user's Kaggle API key.
  void updateKaggleCreds(String kaggleUsername, String kaggleApiKey) {
    kaggleCredentials.value = UserApi(
      kaggleUserName: kaggleUsername,
      kaggleApiKey: kaggleApiKey,
    );
  }
}
