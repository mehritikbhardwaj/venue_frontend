import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/session_provider.dart';
import '../providers/view_state.dart';

/// Opens the OTP-entry modal bottom sheet. Returns `true` when verification
/// succeeded (the caller then navigates), `null`/`false` if dismissed.
///
/// Replaces the old standalone OTP screen: the verify step now happens in a
/// sheet layered over the login screen, so the brand hero stays visible behind.
Future<bool?> showOtpSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _OtpSheet(),
  );
}

class _OtpSheet extends StatefulWidget {
  const _OtpSheet();

  @override
  State<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<_OtpSheet> {
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
      Navigator.pop(context, true); // caller handles navigation
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle.
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.inkMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Verify OTP',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Enter the code sent to +91 ${session.pendingMobile ?? ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Demo banner showing the generated OTP.
            // Container(
            //   padding: const EdgeInsets.all(14),
            //   decoration: BoxDecoration(
            //     color: AppTheme.accent.withValues(alpha: 0.12),
            //     borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            //     border: Border.all(
            //       color: AppTheme.accent.withValues(alpha: 0.4),
            //     ),
            //   ),
            //   child: Row(
            //     children: [
            //       const Icon(Icons.sms_rounded, color: AppTheme.accent),
            //       const SizedBox(width: 12),
            //       Expanded(
            //         child: Text.rich(
            //           TextSpan(
            //             children: [
            //               // const TextSpan(
            //               //   text: 'Demo OTP:  ',
            //               //   style: TextStyle(color: AppTheme.inkMuted, fontSize: 13),
            //               // ),
            //               TextSpan(
            //                 text: session.generatedOtp ?? '------',
            //                 style: const TextStyle(
            //                   color: AppTheme.ink,
            //                   fontWeight: FontWeight.w800,
            //                   letterSpacing: 3,
            //                   fontSize: 16,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              enabled: !loading,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                letterSpacing: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                hintText: '••••••',
              ),
              onSubmitted: (_) => loading ? null : _verify(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _verify,
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Verify & continue'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(context, false),
              child: const Text('Change number'),
            ),
          ],
        ),
      ),
    );
  }
}
