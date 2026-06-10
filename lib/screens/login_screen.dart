import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/session_provider.dart';
import '../providers/view_state.dart';
import '../widgets/otp_sheet.dart';

/// Step 1 of login: enter a 10-digit mobile number and request an OTP.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final session = context.read<SessionProvider>();
    final ok = await session.requestOtp(_mobileController.text.trim());
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.errorMessage ?? 'Could not send OTP')),
      );
      return;
    }
    // Verify the OTP in a bottom sheet layered over this screen.
    final verified = await showOtpSheet(context);
    if (verified != true || !mounted) return;
    // New users set their name; returning users go straight to venues.
    context.go(session.currentUser!.needsName ? '/complete-profile' : '/venues');
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final loading = session.requestState == ViewState.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),

              // ---- Brand mark ------------------------------------------
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppTheme.tileShadow,
                  ),
                  child: const Icon(Icons.bolt_rounded, size: 44, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to QuickSlot',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your mobile number to continue.\nWe’ll text you a one-time code.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.45, color: AppTheme.inkMuted),
              ),

              const Spacer(flex: 2),

              // ---- Form -------------------------------------------------
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  enabled: !loading,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: AppTheme.ink,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Mobile number',
                    hintText: '98765 43210',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Center(
                        widthFactor: 1,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '+91',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    // soft grey fill so the field reads as "fill me in"
                    fillColor: const Color(0xFFF4F7F4),
                    counterText: '',
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.length != 10) {
                      return 'Enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => loading ? null : _requestOtp(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: loading ? null : _requestOtp,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Continue'),
              ),

              const Spacer(flex: 3),

              // ---- Footer ----------------------------------------------
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'By continuing you agree to our Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.inkMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
