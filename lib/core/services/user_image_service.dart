import 'package:flutter/cupertino.dart';

/// A singleton service for managing the user's profile image.
///
/// This service provides a centralized way to store and access the user's
/// profile image URL across the application. It maintains both a ValueNotifier
/// for reactive UI updates and a cached version of the URL.
class UserImageService {
  /// Private singleton instance of [UserImageService]
  static final UserImageService _instance = UserImageService._internal();

  /// Factory constructor that returns the singleton instance
  factory UserImageService() => _instance;

  /// Private constructor for singleton implementation
  UserImageService._internal();

  /// A ValueNotifier that holds the current profile image URL
  ///
  /// UI components can listen to this for reactive updates when the image changes
  final ValueNotifier<String?> profileImageUrl = ValueNotifier<String?>(null);

  /// Cached version of the profile image URL
  String? _cachedUrl;

  /// Updates the profile image URL and notifies listeners
  ///
  /// @param url The new profile image URL or null if no image is available
  void updateProfileImageUrl(String? url) {
    _cachedUrl = url;
    profileImageUrl.value = url;
  }

  /// Getter to access the cached profile image URL
  String? get cachedUrl => _cachedUrl;
}
