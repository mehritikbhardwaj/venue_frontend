import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/view_state.dart';

/// Step 2 of login: enter the OTP. For the demo the OTP comes back in the
/// request response, so we display it here and pre-fill the field.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with the OTP returned by the backend (demo convenience).
    _otpController.text = context.read<SessionProvider>().generatedOtp ?? '';
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final session = context.read<SessionProvider>();
    final ok = await session.verifyOtp(_otpController.text.trim());
    if (!mounted) return;
    if (ok) {
      // New users go set their name; returning users go straight to venues.
      // (The router's redirect also enforces this, but we navigate explicitly.)
      context.go(
        session.currentUser!.needsName ? '/complete-profile' : '/venues',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.errorMessage ?? 'Verification failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final loading = session.verifyState == ViewState.loading;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the OTP sent to +91 ${session.pendingMobile ?? ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              // Demo banner showing the generated OTP.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sms_rounded, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    // Expanded(
                    //   child: Text(
                    //     'Demo OTP: ${session.generatedOtp ?? '------'}',
                    //     style: TextStyle(
                    //       color: scheme.onPrimaryContainer,
                    //       fontWeight: FontWeight.bold,
                    //       letterSpacing: 2,
                    //       fontSize: 16,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                enabled: !loading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  counterText: '',
                  hintText: '------',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: loading ? null : _verify,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify & continue'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: loading ? null : () => context.pop(),
                child: const Text('Change number'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
