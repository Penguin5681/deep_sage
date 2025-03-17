import 'package:hive_flutter/adapters.dart';

part 'user_api_model.g.dart';

/// A model class to store user API credentials for Kaggle
///
/// This class is annotated with Hive annotations to enable
/// persistent storage of user API information using Hive database.
@HiveType(typeId: 0)
class UserApi {
  /// The username for Kaggle account
  @HiveField(0)
  final String kaggleUserName;

  /// The API key associated with the Kaggle account
  @HiveField(1)
  final String kaggleApiKey;

  /// The method used for authentication
  @HiveField(2)
  final String loginMethod;

  /// Creates a new UserApi instance
  ///
  /// [kaggleUserName] is the username for the Kaggle account
  /// [kaggleApiKey] is the API key for the Kaggle account
  /// [loginMethod] represents the authentication method used (defaults to empty string)
  UserApi({
    required this.kaggleApiKey,
    required this.kaggleUserName,
    this.loginMethod = '',
  });
}
