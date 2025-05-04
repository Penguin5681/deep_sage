import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleButton extends StatelessWidget {
  final VoidCallback onSignInSuccess; // Callback for successful sign-in
  const GoogleButton({super.key, required this.onSignInSuccess});

  Future<void> _signInWithGoogle(BuildContext context) async {
    final jsonString = await rootBundle.loadString('assets/client_secret.json');
    final jsonMap = jsonDecode(jsonString)['installed'];

    final clientId = jsonMap['client_id'];
    final clientSecret = jsonMap['client_secret'];
    final redirectUrl = jsonMap['redirect_uris'][0];

    final authorizationEndpoint = Uri.parse(
      'https://accounts.google.com/o/oauth2/auth',
    );
    final tokenEndpoint = Uri.parse('https://oauth2.googleapis.com/token');

    final grant = oauth2.AuthorizationCodeGrant(
      clientId,
      authorizationEndpoint,
      tokenEndpoint,
      secret: clientSecret,
    );

    final authorizationUrl = grant.getAuthorizationUrl(
      Uri.parse(redirectUrl),
      scopes: ['email', 'profile'],
    );

    if (await canLaunchUrl(authorizationUrl)) {
      await launchUrl(authorizationUrl);
    } else {
      throw 'Could not launch $authorizationUrl';
    }

    // Capture the redirect URI (requires a local server)
    final responseUrl = await _captureRedirect(redirectUrl);

    // Exchange the authorization code for tokens
    final client = await grant.handleAuthorizationResponse(
      responseUrl.queryParameters,
    );

    // Use the access token to authenticate with Supabase
    final supabase = Supabase.instance.client;
    final AuthResponse res = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: client.credentials.idToken!,
      accessToken: client.credentials.accessToken,
    );

    // Get user from response
    final User? user = res.user;

    if (user == null) {
      throw Exception('No users found after Google sign-in');
    }

    final userBox = Hive.box(dotenv.env['USER_HIVE_BOX']!);
    await userBox.put('userSessionToken', res.session!.accessToken);
    await userBox.put('loginMethod', 'google');

    // Store user profile information in Supabase profiles table
    await supabase.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'display_name': user.userMetadata?['display_name'] ?? 'User',
      'avatar_url': user.userMetadata?['avatar_url'],
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Successfully signed in')));
    }
  }

  Future<Uri> _captureRedirect(String redirectUrl) async {
    // Implement a local server to capture the redirect URL
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
    final request = await server.first;
    final responseUrl = request.uri;

    // Send a response to the browser
    request.response
      ..statusCode = 200
      ..write('You can now close this window.')
      ..close();

    // Close the server
    await server.close();

    return responseUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            try {
              await _signInWithGoogle(context);
              onSignInSuccess();
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error signing in: $error')),
              );
              debugPrint('Google Sign-In Error: $error');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/google_icon.png',
                  height: 24,
                  width: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sign in with Google',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
