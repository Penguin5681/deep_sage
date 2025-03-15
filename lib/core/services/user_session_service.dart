import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Checks if a valid user session exists.
///
/// This function verifies if there is an existing user session by:
/// 1. Checking for a stored session token in Hive local storage
/// 2. Verifying if there is a current authenticated user in Supabase
/// 3. Attempting to recover the session using the stored token if needed
///
/// Returns:
/// * `true` if a valid session exists or was successfully recovered
/// * `false` if no session exists or the session recovery failed
///
/// Throws:
/// * Catches and logs any exceptions that occur during the process
Future<bool> checkExistingSession() async {
  try {
    final userBox = await Hive.openBox(dotenv.env['USER_HIVE_BOX']!);
    final sessionToken = userBox.get('userSessionToken');

    if (sessionToken != null) {
      final supabase = Supabase.instance.client;

      final user = supabase.auth.currentUser;

      if (user != null) {
        return true;
      } else {
        try {
          await supabase.auth.recoverSession(sessionToken);
          return true;
        } catch (e) {
          await userBox.delete('userSessionToken');
          return false;
        }
      }
    }
    return false;
  } catch (e) {
    debugPrint('Error checking session: $e');
    return false;
  }
}
