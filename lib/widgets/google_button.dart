import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleButton extends StatelessWidget {
  final VoidCallback onSignInSuccess; // Callback for successful sign-in
  const GoogleButton({super.key, required this.onSignInSuccess});

  // Future<void> _signInWithGoogle(BuildContext context) async {
  //   try {
  //     // Initialize google sign in
  //     final GoogleSignIn googleSignIn = GoogleSignIn(
  //       scopes: ['email', 'profile'],
  //     );

  //     // Start the Google sign-in flow
  //     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  //     if (googleUser == null) {
  //       // User canceled the sign-in
  //       return;
  //     }

  //     // Get authentication details
  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;

  //     // Get Supabase client
  //     final supabase = Supabase.instance.client;

  //     // Sign in to supabase with google OAuth
  //     final AuthResponse res = await supabase.auth.signInWithIdToken(
  //       provider: OAuthProvider.google,
  //       idToken: googleAuth.idToken!,
  //       accessToken: googleAuth.accessToken,
  //     );

  //     // Get user from response
  //     final User? user = res.user;

  //     if (user == null) {
  //       throw Exception('No users found after Google sign-in');
  //     }

  //     // Store user profile information in Supabase profiles table
  //     await supabase.from('profiles').upsert({
  //       'id': user.id,
  //       'email': googleUser.email,
  //       'display_name': googleUser.displayName ?? 'User',
  //       'avatar_url': googleUser.photoUrl,
  //       'updated_at': DateTime.now().toIso8601String(),
  //     });

  //     // Show success message
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text('Successfully signed in')));
  //     }
  //   } catch (error) {
  //     // Show error message
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Error signing in: $error')));
  //     }
  //     debugPrint('Google sign-in error: $error');
  //   }
  // }

  // Future<void> _signInWithGoogle(BuildContext context) async {
  //   // Load the JSON file from assets
  //   final jsonString = await rootBundle.loadString('assets/client_secret.json');
  //   final jsonMap = jsonDecode(jsonString)['installed'];

  //   final clientId = jsonMap['client_id'];
  //   final clientSecret = jsonMap['client_secret'];
  //   final redirectUrl = jsonMap['redirect_uris'][0];

  //   // Initialize OAuth2 grant
  //   final authorizationEndpoint = Uri.parse(
  //     'https://accounts.google.com/o/oauth2/auth',
  //   );
  //   final tokenEndpoint = Uri.parse('https://oauth2.googleapis.com/token');

  //   final grant = oauth2.AuthorizationCodeGrant(
  //     clientId,
  //     authorizationEndpoint,
  //     tokenEndpoint,
  //     secret: clientSecret,
  //   );

  //   // Generate the authorization URL with the required scopes
  //   final authorizationUrl = grant.getAuthorizationUrl(
  //     Uri.parse(redirectUrl),
  //     scopes: ['email', 'profile'], // Add the required scopes
  //   );

  //   // Open the OAuth consent screen in a browser
  //   final authorizationUrl = grant.getAuthorizationUrl(Uri.parse(redirectUrl));
  //   if (await canLaunchUrl(authorizationUrl)) {
  //     await launchUrl(authorizationUrl);
  //   } else {
  //     throw 'Could not launch $authorizationUrl';
  //   }

  //   // Capture the redirect URI (requires a local server)
  //   final responseUrl = await _captureRedirect(redirectUrl);

  //   // Exchange the authorization code for tokens
  //   final client = await grant.handleAuthorizationResponse(
  //     responseUrl.queryParameters,
  //   );

  //   // Use the access token to authenticate with Supabase
  //   final supabase = Supabase.instance.client;
  //   final AuthResponse res = await supabase.auth.signInWithIdToken(
  //     provider: OAuthProvider.google,
  //     idToken: client.credentials.idToken!,
  //     accessToken: client.credentials.accessToken,
  //   );

  //   // Get user from response
  //   final User? user = res.user;

  //   if (user == null) {
  //     throw Exception('No users found after Google sign-in');
  //   }

  //   // Store user profile information in Supabase profiles table
  //   await supabase.from('profiles').upsert({
  //     'id': user.id,
  //     'email': user.email,
  //     'display_name': user.userMetadata?['display_name'] ?? 'User',
  //     'avatar_url': user.userMetadata?['avatar_url'],
  //     'updated_at': DateTime.now().toIso8601String(),
  //   });

  //   // Show success message
  //   if (context.mounted) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text('Successfully signed in')));
  //   }
  // }

  Future<void> _signInWithGoogle(BuildContext context) async {
  // Load the JSON file from assets
  final jsonString = await rootBundle.loadString('assets/client_secret.json');
  final jsonMap = jsonDecode(jsonString)['installed'];

  final clientId = jsonMap['client_id'];
  final clientSecret = jsonMap['client_secret'];
  final redirectUrl = jsonMap['redirect_uris'][0];

  // Initialize OAuth2 grant
  final authorizationEndpoint = Uri.parse('https://accounts.google.com/o/oauth2/auth');
  final tokenEndpoint = Uri.parse('https://oauth2.googleapis.com/token');

  final grant = oauth2.AuthorizationCodeGrant(
    clientId,
    authorizationEndpoint,
    tokenEndpoint,
    secret: clientSecret,
  );

  // Generate the authorization URL with the required scopes
  final authorizationUrl = grant.getAuthorizationUrl(
    Uri.parse(redirectUrl),
    scopes: ['email', 'profile'], // Add the required scopes
  );

  // Open the OAuth consent screen in a browser
  if (await canLaunchUrl(authorizationUrl)) {
    await launchUrl(authorizationUrl);
  } else {
    throw 'Could not launch $authorizationUrl';
  }

  // Capture the redirect URI (requires a local server)
  final responseUrl = await _captureRedirect(redirectUrl);

  // Exchange the authorization code for tokens
  final client = await grant.handleAuthorizationResponse(responseUrl.queryParameters);

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully signed in')),
    );
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
    return SizedBox(
      height: 40.0,
      width: 80.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: Theme.of(context).textTheme.headlineSmall?.color,
        ),
        // onPressed: () async {
        //   _signInWithGoogle(context); // Perform Google Sign-In

        // },
        onPressed: () async {
        try {
          await _signInWithGoogle(context); // Perform Google Sign-In
          onSignInSuccess(); // Trigger the callback after successful sign-in
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing in: $error')),
          );
          debugPrint('Google Sign-In Error: $error');
        }
      },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.google,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
