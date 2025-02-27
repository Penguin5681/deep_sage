import 'package:flutter/material.dart';
import 'package:deep_sage/widgets/primary_button.dart';
import 'package:deep_sage/widgets/secondary_button.dart';

class SignOutScreen extends StatefulWidget {
  const SignOutScreen({super.key});

  @override
  State<SignOutScreen> createState() => _SignOutScreenState();
}

class _SignOutScreenState extends State<SignOutScreen> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.logout,
                        size: 24,
                        color: Color(0xFFFF003F),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF003F), // Updated color
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to sign out? All unsaved changes will be lost.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  PrimaryButton(
                    text: 'Sign Out',
                    onPressed: () {
                      // Handle sign-out logic
                    },
                  ),
                  const SizedBox(width: 12),
                  SecondaryButton(
                    text: 'Cancel',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
