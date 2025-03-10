import 'package:flutter/cupertino.dart';

class UserImageService {
  static final UserImageService _instance = UserImageService._internal();
  factory UserImageService() => _instance;
  UserImageService._internal();

  final ValueNotifier<String?> profileImageUrl = ValueNotifier<String?>(null);
  String? _cachedUrl;

  void updateProfileImageUrl(String? url) {
    _cachedUrl = url;
    profileImageUrl.value = url;
  }

  String? get cachedUrl => _cachedUrl;
}