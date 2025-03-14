import 'package:hive_flutter/adapters.dart';

part 'user_api_model.g.dart';

@HiveType(typeId: 0)
class UserApi {
  @HiveField(0)
  final String kaggleUserName;

  @HiveField(1)
  final String kaggleApiKey;

  @HiveField(2)
  final String loginMethod;

  UserApi({
    required this.kaggleApiKey,
    required this.kaggleUserName,
    this.loginMethod = ''
  });
}