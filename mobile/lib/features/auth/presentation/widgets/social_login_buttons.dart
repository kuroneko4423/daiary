import 'package:flutter/material.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGoogleSignIn;
  final VoidCallback? onAppleSignIn;

  const SocialLoginButtons({super.key, this.onGoogleSignIn, this.onAppleSignIn});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: onGoogleSignIn,
          icon: const Icon(Icons.g_mobiledata),
          label: const Text('Sign in with Google'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAppleSignIn,
          icon: const Icon(Icons.apple),
          label: const Text('Sign in with Apple'),
        ),
      ],
    );
  }
}
