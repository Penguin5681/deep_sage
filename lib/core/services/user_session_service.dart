import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> checkExistingSession() async {
  try {
    final userBox = await Hive.openBox(dotenv.env['USER_HIVE_BOX']!);
    final sessionToken = userBox.get('userSessionToken');

    if (sessionToken != null) {
      final supabase = Supabase.instance.client;

      final user = supabase.auth.currentUser;

      if (user != null) {
        return true; // Session is valid
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