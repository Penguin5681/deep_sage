import 'package:flutter/cupertino.dart';

class UserImageService {
  static final UserImageService _instance = UserImageService._internal();
  factory UserImageService() => _instance;
  UserImageService._internal();

  final ValueNotifier<String?> profileImageUrl = ValueNotifier<String?>(null);

  void updateProfileImageUrl(String? url) {
    profileImageUrl.value = url;
  }
}